module letsmovectf::user {
    use sui::transfer::{share_object, public_transfer};
    use sui::table::{Self, Table};
    use std::string::{Self, String};
    use sui::clock::Clock;
    use letsmovectf::checkAcount::{UnCheckUserList, addUncheckUser, new_uncheck_list, remove_uncheck_user};
    use sui::event;
    use sui::nitro_attestation::index;
    use sui::vec_map::{Self, VecMap};
    use letsmovectf::admin::AdminCap;

    // Error codes
    const EUSER_NOT_FOUND: u64 = 1;      // User does not exist
    const EUSER_ALREADY_EXISTS: u64 = 2; // User already exists
    const EAVATAR_NOT_FOUND: u64 = 3;    // Avatar blob_id not found in user's list
    const ECHALLENGE_ALREADY_EXISTS: u64 = 4; // Challenge ID already exists
    const EWRITEUP_ALREADY_EXISTS: u64 = 5;   // WriteUp ID already exists


    // User structure
    public struct User has key, store {
        id: UID,
        email_hash: Option<String>,            // Hash of user's email (SHA-256)
        github_id: Option<String>,             // GitHub ID
        avatars: vector<String>,       // List of avatar blob_ids (from Walrus)
        points: u64,                   // Points from solving challenges
        challenges: Table<u64, u64>,   // List of submitted Challenge IDs with timestamps
        solved_challenges: Table<u64, u64>, // List of solved Challenge IDs with timestamps
        writeups: Table<u64, u64>,     // List of submitted WriteUp IDs with timestamps
        abilities: VecMap<String, u64>, // Ability scores (category -> points)
        team: Option<address>,         // Team owner address (if in a team)
        registered_at: u64,            // Registration timestamp (epoch)
        github_vaild:bool,
    }


    // Global user list
    public struct UserList has key {
        id: UID,
        users: Table<address, User>,   // Mapping of address to User
    }


    // Event: User registered
    public struct UserRegistered has copy, drop {
        user: address,
        github_id: String,
        avatars: vector<String>,       // Initial list of avatars (empty at registration)
        registered_at: u64,
    }

    // Event: Challenge solved
    public struct ChallengeSolved has copy, drop {
        user: address,
        challenge_id: u64,
        category: String,
        points: u64,
        timestamp: u64,
    }

    // Event: Challenge submitted
    public struct ChallengeSubmitted has copy, drop {
        user: address,
        challenge_id: u64,
        timestamp: u64,
    }

    // Event: WriteUp submitted
    public struct WriteUpSubmitted has copy, drop {
        user: address,
        writeup_id: u64,
        challenge_id: u64,
        timestamp: u64,
    }

    // Event: Points added
    public struct PointsAdded has copy, drop {
        user: address,
        points: u64,
        reason: String,
    }


    // Event: User avatar added
    public struct UserAvatarAdded has copy, drop {
        user: address,
        blob_id: String,
    }

    // Event: User avatar removed
    public struct UserAvatarRemoved has copy, drop {
        user: address,
        blob_id: String,
    }

    // Event: User joined a team
    public struct UserJoinedTeam has copy, drop {
        user: address,
        team_owner: address,
    }

    // Event: User left a team
    public struct UserLeftTeam has copy, drop {
        user: address,
        team_owner: address,
    }



    // Initialize the UserList
    fun init(ctx: &mut TxContext) {
        share_object(UserList {
            id: object::new(ctx),
            users: table::new(ctx),
        });

        new_uncheck_list(ctx);
    }

    // Register a new user
    public entry fun register_user(
        email_hash:Option<String>,
        github_id:Option<String>,
        list: &mut UserList,
        unchecklist:&mut UnCheckUserList,
        clock:&Clock,
        ctx: &mut TxContext
    ) {
        let user_addr = tx_context::sender(ctx);
        assert!(!table::contains(&list.users, user_addr), EUSER_ALREADY_EXISTS); // Ensure user doesn't exist
        let user = User {
            id: object::new(ctx),
            email_hash,
            github_id,
            avatars: vector::empty(),  // Initialize with an empty list
            points: 0,
            challenges: table::new(ctx),
            solved_challenges: table::new(ctx),
            writeups: table::new(ctx),
            abilities: vec_map::empty(),
            github_vaild:false,
            team: option::none(),
            registered_at: tx_context::epoch(ctx),
        };
        addUncheckUser(unchecklist,user_addr,clock);

        table::add(&mut list.users, user_addr, user);
        event::emit(UserRegistered {
            user: user_addr,
            github_id: string::utf8(b""),
            avatars: vector::empty(),
            registered_at: tx_context::epoch(ctx),
        });
    }

    // Check user Account
    public entry fun Check_user_account(
        _admin:&AdminCap,
        userlist:&mut UserList,
        uncheckuserlist:&mut UnCheckUserList,
        user_address:address,
    ){
        assert!(table::contains(&userlist.users,user_address),EUSER_NOT_FOUND);
        let user=table::borrow_mut(&mut userlist.users,user_address);
        user.github_vaild=true;
        remove_uncheck_user(user_address,uncheckuserlist);
    }
    // Record a challenge solve (callable by other modules)
    public entry fun record_solve(
        user_addr: address,
        challenge_id: u64,
        category: String,
        points: u64,
        list: &mut UserList,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        user.points = user.points + points;

        // Add to solved challenges with timestamp
        let timestamp = tx_context::epoch_timestamp_ms(ctx);
        table::add(&mut user.solved_challenges, challenge_id, timestamp);

        // Update ability scores
        if (vec_map::contains(&user.abilities, &category)) {
            let current = vec_map::get_mut(&mut user.abilities, &category);
            *current = *current + points;
        } else {
            vec_map::insert(&mut user.abilities, category, points);
        };

        event::emit(ChallengeSolved {
            user: user_addr,
            challenge_id,
            category,
            points,
            timestamp,
        });
    }



    public entry fun add_points(
        _admin:&AdminCap,
        user_addr: address,
        points: u64,
        reason: String,
        list: &mut UserList,
        _: &mut TxContext
    ) {
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        user.points = user.points + points;

        event::emit(PointsAdded {
            user: user_addr,
            points,
            reason,
        });
    }


    // Set user's team (callable by user or team module)
    public(package) fun set_team(
        user_addr: address,
        team_owner: address,
        list: &mut UserList,
    ) {
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        user.team = option::some(team_owner);

        event::emit(UserJoinedTeam {
            user: user_addr,
            team_owner,
        });
    }

    // Clear user's team (called by team module when user leaves or team is deleted)
    public(package) fun clear_team(
        user_addr: address,
        team_owner: address,
        list: &mut UserList,
    ) {
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        assert!(option::is_some(&user.team), 0); // Ensure user is in a team
        assert!(*option::borrow(&user.team) == team_owner, 0); // Ensure the team matches

        user.team = option::none();
        event::emit(UserLeftTeam {
            user: user_addr,
            team_owner,
        });
    }

    // Save a user email (by user)
    public entry fun save_user_email(
        email: Option<String>,
        list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let user_addr = tx_context::sender(ctx);
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        user.email_hash = email;
    }

    // Save a user github_id (by user)
    public entry fun save_user_github_id(
        github_id: Option<String>,
        list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let user_addr = tx_context::sender(ctx);
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        user.github_id = github_id;
    }

    // Add a user avatar (by user)
    public entry fun add_user_avatar(
        blob_id: String,
        list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let user_addr = tx_context::sender(ctx);
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        vector::push_back(&mut user.avatars, blob_id);

        event::emit(UserAvatarAdded {
            user: user_addr,
            blob_id,
        });
    }

    // Remove a user avatar (by user)
    public entry fun remove_user_avatar(
        blob_id: String,
        list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let user_addr = tx_context::sender(ctx);
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        let (found, index) = vector::index_of(&user.avatars, &blob_id);
        assert!(found, EAVATAR_NOT_FOUND); // Ensure the blob_id exists in the list

        vector::remove(&mut user.avatars, index);
        event::emit(UserAvatarRemoved {
            user: user_addr,
            blob_id,
        });
    }

    // Remove a user avatar (by admin)
    public entry fun remove_user_avatar_by_admin(
        _: &AdminCap,
        user_addr: address,
        blob_id: String,
        list: &mut UserList,
        _: &mut TxContext
    ) {
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists

        let user = table::borrow_mut(&mut list.users, user_addr);
        let (found, index) = vector::index_of(&user.avatars, &blob_id);
        assert!(found, EAVATAR_NOT_FOUND); // Ensure the blob_id exists in the list

        vector::remove(&mut user.avatars, index);
        event::emit(UserAvatarRemoved {
            user: user_addr,
            blob_id,
        });
    }

    // Get user information
    public fun get_user_info(list: &UserList, user_addr: address): &User{
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists
        let user = table::borrow(&list.users, user_addr);
        user
    }


    // Get user registration time
    public fun get_registered_at(list: &UserList, user_addr: address): u64 {
        assert!(table::contains(&list.users, user_addr), EUSER_NOT_FOUND); // Ensure user exists
        let user = table::borrow(&list.users, user_addr);
        user.registered_at
    }
}