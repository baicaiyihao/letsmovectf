module letsmovectf::team {
    use sui::table::{Self, Table};
    use std::string::{Self, String};
    use sui::event;
    use sui::vec_set::{Self, VecSet};
    use letsmovectf::admin::AdminCap;
    use letsmovectf::user::{Self, UserList};

    // Error codes
    const ETEAM_NOT_FOUND: u64 = 1;      // Team does not exist
    const ENOT_OWNER: u64 = 2;           // Caller is not the team owner
    const EALREADY_MEMBER: u64 = 3;      // Address is already a member
    const ENOT_MEMBER: u64 = 4;          // Address is not a member
    const EALREADY_REQUESTED: u64 = 5;   // Address has already requested to join
    const ENOT_REQUESTED: u64 = 6;       // Address has not requested to join

    // Team structure
    public struct Team has key, store {
        id: UID,
        name: String,                   // Team name
        description: String,            // Team description
        avatar: String,                 // Team avatar blob_ids (from Walrus)
        owner: address,                 // Team owner address
        members: VecSet<address>,       // List of team members (excluding owner)
        requests: VecSet<address>,      // List of addresses requesting to join
        created_at: u64,                // Creation timestamp (epoch)
    }

    // Global team list
    public struct TeamList has key {
        id: UID,
        teams: Table<address, Team>,    // Mapping of owner address to Team
    }

    // Event: Team created
    public struct TeamCreated has copy, drop {
        owner: address,
        name: String,                   // Team name
        avatar: String,                 // Team avatar
        created_at: u64,
    }

    // Event: Member joined the team
    public struct MemberJoined has copy, drop {
        team_owner: address,
        member: address,
    }

    // Event: Member removed from the team
    public struct MemberRemoved has copy, drop {
        team_owner: address,
        member: address,
    }

    // Event: Team deleted
    public struct TeamDeleted has copy, drop {
        owner: address,
    }

    // Event: Join request submitted
    public struct JoinRequested has copy, drop {
        team_owner: address,
        requester: address,
    }

    // Event: Team avatar updated
    public struct TeamAvatarUpdated has copy, drop {
        team_owner: address,
        new_avatar: String,
    }

    // Initialize TeamList
    fun init(ctx: &mut TxContext) {
        transfer::share_object(TeamList {
            id: object::new(ctx),
            teams: table::new(ctx),
        });
    }

    // Create a new team
    public entry fun create_team(
        name: String,
        description: String,
        avatar: String,
        list: &mut TeamList,
        user_list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        assert!(!table::contains(&list.teams, owner), ETEAM_NOT_FOUND);

        let team = Team {
            id: object::new(ctx),
            name,
            description,
            avatar,
            owner,
            members: vec_set::empty(),
            requests: vec_set::empty(),
            created_at: tx_context::epoch(ctx),
        };

        table::add(&mut list.teams, owner, team);
        user::set_team(owner, owner, user_list); // Set the owner's team
        event::emit(TeamCreated {
            owner,
            name,
            avatar,
            created_at: tx_context::epoch(ctx),
        });
    }

    // Request to join a team
    public entry fun request_join(
        team_owner: address,
        list: &mut TeamList,
        ctx: &mut TxContext
    ) {
        let requester = tx_context::sender(ctx);
        assert!(table::contains(&list.teams, team_owner), ETEAM_NOT_FOUND);

        let team = table::borrow_mut(&mut list.teams, team_owner);
        assert!(!vec_set::contains(&team.members, &requester), EALREADY_MEMBER);
        assert!(!vec_set::contains(&team.requests, &requester), EALREADY_REQUESTED);

        vec_set::insert(&mut team.requests, requester);
        event::emit(JoinRequested {
            team_owner,
            requester,
        });
    }

    // Approve a join request
    public entry fun approve_join(
        member: address,
        list: &mut TeamList,
        user_list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        assert!(table::contains(&list.teams, owner), ETEAM_NOT_FOUND);

        let team = table::borrow_mut(&mut list.teams, owner);
        assert!(team.owner == owner, ENOT_OWNER);
        assert!(vec_set::contains(&team.requests, &member), ENOT_REQUESTED);

        vec_set::remove(&mut team.requests, &member);
        vec_set::insert(&mut team.members, member);
        user::set_team(member,owner, user_list); // Update the member's team
        event::emit(MemberJoined {
            team_owner: owner,
            member,
        });
    }

    // Remove a member from the team
    public entry fun remove_member(
        member: address,
        list: &mut TeamList,
        user_list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        assert!(table::contains(&list.teams, owner), ETEAM_NOT_FOUND); // Ensure the team exists

        let team = table::borrow_mut(&mut list.teams, owner);
        assert!(team.owner == owner, ENOT_OWNER); // Ensure caller is the owner
        assert!(vec_set::contains(&team.members, &member), ENOT_MEMBER); // Ensure member is in the team

        vec_set::remove(&mut team.members, &member);
        user::clear_team(member, owner, user_list); // Clear the member's team
        event::emit(MemberRemoved {
            team_owner: owner,
            member,
        });
    }

    // Delete the team (by owner)
    public entry fun delete_team(
        list: &mut TeamList,
        user_list: &mut UserList,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        assert!(table::contains(&list.teams, owner), ETEAM_NOT_FOUND); // Ensure the team exists

        let team = table::remove(&mut list.teams, owner);
        assert!(team.owner == owner, ENOT_OWNER); // Ensure caller is the owner

        // Clear team for owner
        user::clear_team(owner, owner, user_list);

        // Clear team for all members
        let members = vec_set::into_keys(team.members);
        let len = vector::length(&members);
        let mut i = 0;
        while (i < len) {
            let member = *vector::borrow(&members, i);
            user::clear_team(member, owner, user_list);
            i = i + 1;
        };

        let Team { id, name: _, description: _, avatar: _, owner, members: _, requests: _, created_at: _ } = team;
        object::delete(id);
        event::emit(TeamDeleted {
            owner,
        });
    }

    // Delete the team (by admin)
    public entry fun delete_team_by_admin(
        _: &AdminCap,
        list: &mut TeamList,
        user_list: &mut UserList,
        team_owner: address,
    ) {
        assert!(table::contains(&list.teams, team_owner), ETEAM_NOT_FOUND); // Ensure the team exists
        let team = table::remove(&mut list.teams, team_owner);

        // Clear team for owner
        user::clear_team(team_owner, team_owner, user_list);

        // Clear team for all members
        let members = vec_set::into_keys(team.members);
        let len = vector::length(&members);
        let mut i = 0;
        while (i < len) {
            let member = *vector::borrow(&members, i);
            user::clear_team(member, team_owner, user_list);
            i = i + 1;
        };

        let Team { id, name: _, description: _, avatar: _, owner, members: _, requests: _, created_at: _ } = team;
        object::delete(id);
        event::emit(TeamDeleted {
            owner,
        });
    }

    // Set team avatar (by owner)
    public entry fun set_team_avatar(
        avatar: vector<u8>,
        list: &mut TeamList,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        assert!(table::contains(&list.teams, owner), ETEAM_NOT_FOUND); // Ensure the team exists

        let team = table::borrow_mut(&mut list.teams, owner);
        assert!(team.owner == owner, ENOT_OWNER); // Ensure caller is the owner

        team.avatar = string::utf8(avatar);
        event::emit(TeamAvatarUpdated {
            team_owner: owner,
            new_avatar: team.avatar,
        });
    }

    // Set team avatar (by admin)
    public entry fun set_team_avatar_by_admin(
        _: &AdminCap,
        team_owner: address,
        avatar: vector<u8>,
        list: &mut TeamList,
    ) {
        assert!(table::contains(&list.teams, team_owner), ETEAM_NOT_FOUND); // Ensure the team exists

        let team = table::borrow_mut(&mut list.teams, team_owner);
        team.avatar = string::utf8(avatar);
        event::emit(TeamAvatarUpdated {
            team_owner,
            new_avatar: team.avatar,
        });
    }

    // Get team information
    public fun get_team_info(list: &TeamList, team_owner: address): &Team {
        assert!(table::contains(&list.teams, team_owner), ETEAM_NOT_FOUND); // Ensure the team exists
        let team = table::borrow(&list.teams, team_owner);
        team
    }

    // Get the total number of teams
    public fun get_team_count(list: &TeamList): u64 {
        table::length(&list.teams)
    }
}