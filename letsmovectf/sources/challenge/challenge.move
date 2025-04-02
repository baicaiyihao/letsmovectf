module letsmovectf::challenge;
use std::string::{String};
use sui::balance;
use letsmovectf::admin::AdminCap;
use sui::balance::Balance;
use sui::balance::{join as join_balance,split as split_balance};
use sui::coin::{Coin, into_balance, from_balance,split as split_coin};
use sui::table;
use sui::table::Table;
use sui::transfer::{share_object, public_transfer};
use sui::tx_context::sender;
use sui::vec_set::{VecSet, empty};


public struct Challenge has key,store{
            id: UID,
            challenge_id: u64,              // 唯一题目ID
            contact_id:address,             // 题目合约地址
            category: String,               // 题目分类（如"WEB", "MISC"）
            title: String,                  // 题目标题
            tips:Option<String>,                    //题目提示
            description: String,            // 题目描述
            points: u64,                    // 解题积分
            reward_coins: u64,              // 解题奖励金币
            first_blood_reward: u64,        // 一血奖励金币
            second_blood_reward: u64,       // 二血奖励金币
            third_blood_reward: u64,        // 三血奖励金币
            solved_count: u64,              // 已解决人数
            solvers: VecSet<address>,       // 解决者列表
            first_blood: Option<address>,   // 一血用户
            second_blood: Option<address>,  // 二血用户
            third_blood: Option<address>,   // 三血用户
            is_published: bool,             // 题目是否已发布
}

public struct ChallengeTable has key{
    id:UID,
    challenge:Table<u64,Challenge>
}

fun init(
    ctx:&mut TxContext
){
    share_object(ChallengeTable{
        id:object::new(ctx),
        challenge:table::new(ctx)
    })
}

public entry fun AddChallenge(
    _admin:&AdminCap,
    challengeTable:&mut ChallengeTable,
    challenge_id: u64,              // 唯一题目ID
    contact_id:address,             // 题目合约地址
    category: String,               // 题目分类（如"WEB", "MISC"）
    title: String,                  // 题目标题
    tips: Option<String>,                    //题目提示
    description: String,            // 题目描述
    points: u64,                    // 解题积分
    reward_coins: u64,              // 解题奖励金币
    first_blood_reward: u64,        // 一血奖励金币
    second_blood_reward: u64,       // 二血奖励金币
    third_blood_reward: u64,        // 三血奖励金币
    solved_count: u64,              // 已解决人数
    first_blood: Option<address>,   // 一血用户
    second_blood: Option<address>,  // 二血用户
    third_blood: Option<address>,   // 三血用户
    is_published: bool,             // 题目是否已发布
    ctx:&mut TxContext,
){
    let challenge=Challenge{
        id:object::new(ctx),
        challenge_id,             // 唯一题目ID
        contact_id,            // 题目合约地址
        category,             // 题目分类（如"WEB", "MISC"）
        title,                 // 题目标题
        tips,                   //题目提示
        description,          // 题目描述
        points,               // 解题积分
        reward_coins,           // 解题奖励金币
        first_blood_reward,    // 一血奖励金币
        second_blood_reward,    // 二血奖励金币
        third_blood_reward,     // 三血奖励金币
        solved_count,         // 已解决人数
        solvers:empty<address>(),     // 解决者列表
        first_blood,   // 一血用户
        second_blood,  // 二血用户
        third_blood,  // 三血用户
        is_published,
    };
    table::add(&mut challengeTable.challenge,challenge_id,challenge);
}

//用于存放题目奖励代币。
public struct FlagAccount<phantom T> has key{
    id:UID,
    flag_coin:Balance<T>
}

//用于存放兑换代币。
public struct SwapAccount<phantom T> has key{
    id:UID,
    swap_coin:Balance<T>,
    swap_num:u64,
}

//添加Flag代币的方法
public entry fun addFlagCoin<T>(
    _admin:&AdminCap,
    falgPool:&mut FlagAccount<T>,
    flag_coin:Coin<T>,
){
    let flag_coin_balance = into_balance(flag_coin);
    falgPool.flag_coin.join_balance(flag_coin_balance);
}

//创建flag代币池子方法
public entry fun createFlagPool<T>(
    _admin:&AdminCap,
    ctx:&mut TxContext
){
    share_object(FlagAccount<T>{
        id:object::new(ctx),
        flag_coin:balance::zero(),
    })
}

//创建Swap代币池子方法
public entry fun createSwapPool<T>(
    _admin:&AdminCap,
    ctx:&mut TxContext
){
    share_object(SwapAccount<T>{
        id:object::new(ctx),
        swap_coin:balance::zero(),
        swap_num:1428571
    })
}

//修改兑换比例
public entry fun editSwapNum<T>(
    _admin:&AdminCap,
    swapPool:&mut SwapAccount<T>,
    num:u64
){
    swapPool.swap_num=num;
}

//添加Flag代币的方法
public entry fun addSwapCoin<T>(
    _admin:&AdminCap,
    swapPool:&mut SwapAccount<T>,
    swap_coin:Coin<T>,
){
    let swap_coin_balance = into_balance(swap_coin);
    swapPool.swap_coin.join_balance(swap_coin_balance);
}

//兑换flag代币，如将题目1flag代币兑换为Usdc

public entry fun flagSwap<Flag,Swap>(
    flagPool:&mut FlagAccount<Flag>,
    swapPool:&mut SwapAccount<Swap>,
    flagCoin:Coin<Flag>,
    ctx:&mut TxContext
){
    let flag_value = flagCoin.value();
    let mut flag_coin_balance = into_balance(flagCoin);
    join_balance(&mut flagPool.flag_coin,flag_coin_balance);
    let mut swap_coin = from_balance(split_balance(&mut swapPool.swap_coin,flag_value*swapPool.swap_num),ctx);
    let userAddr = sender(ctx);
    transfer::public_transfer(swap_coin,userAddr);
}


//     use sui::object::{Self, UID};
//     use sui::tx_context::{Self, TxContext};
//     use sui::transfer;
//     use sui::table::{Self, Table};
//     use sui::event;
//     use sui::vec_set::{Self, VecSet};
//     use sui::vec_map::{Self, VecMap};
//     use std::string::{Self, String}; // 引入string模块
//     use letsmovectf::admin::AdminCap;
//     use letsmovectf::user::{Self, UserList};

//     // 错误码
//     const ECHALLENGE_NOT_FOUND: u64 = 1;    // 题目不存在
//     const EINVALID_ADMIN: u64 = 2;          // 无效的管理员
//     const EINSUFFICIENT_COINS: u64 = 3;     // 金币不足
//     const EALREADY_SOLVED: u64 = 4;         // 题目已解决
//     const EALREADY_OPENED: u64 = 5;         // 题目已开启

//     // 题目结构体
//     public struct Challenge has key, store {
//         id: UID,
//         challenge_id: u64,              // 唯一题目ID
//         category: String,               // 题目分类（如"WEB", "MISC"）
//         title: String,                  // 题目标题
//         description: String,            // 题目描述
//         points: u64,                    // 解题积分
//         cost_coins: u64,                // 开启题目所需金币
//         reward_coins: u64,              // 解题奖励金币
//         first_blood_reward: u64,        // 一血奖励金币
//         second_blood_reward: u64,       // 二血奖励金币
//         third_blood_reward: u64,        // 三血奖励金币
//         solved_count: u64,              // 已解决人数
//         solvers: VecSet<address>,       // 解决者列表
//         first_blood: Option<address>,   // 一血用户
//         second_blood: Option<address>,  // 二血用户
//         third_blood: Option<address>,   // 三血用户
//         is_published: bool,             // 题目是否已发布
//     }

//     // 全局题目列表
//     public struct ChallengeList has key {
//         id: UID,
//         admin: address,                 // 管理员地址
//         challenges: Table<u64, Challenge>, // 题目映射（ID -> Challenge）
//         categories: VecMap<String, VecSet<u64>>, // 分类映射（分类 -> 题目ID列表）
//         pending_submissions: Table<u64, Challenge>, // 待审核的题目提交
//     }

//     // 事件：题目提交
//     public struct ChallengeSubmitted has copy, drop {
//         challenge_id: u64,
//         submitter: address,
//         category: String,
//         title: String,
//     }

//     // 事件：题目发布
//     public struct ChallengePublished has copy, drop {
//         challenge_id: u64,
//         category: String,
//         title: String,
//     }

//     // 事件：题目开启
//     public struct ChallengeOpened has copy, drop {
//         user: address,
//         challenge_id: u64,
//         cost_coins: u64,
//     }

//     // 事件：题目解决
//     public struct ChallengeSolved has copy, drop {
//         user: address,
//         challenge_id: u64,
//         points: u64,
//         reward_coins: u64,
//         blood_reward: u64,              // 一二三血奖励（如果有）
//         blood_rank: u64,                // 血排名（1, 2, 3，0表示无血奖励）
//     }

//     // 初始化ChallengeList
//     fun init(ctx: &mut TxContext) {
//         let admin = tx_context::sender(ctx);
//         transfer::share_object(ChallengeList {
//             id: object::new(ctx),
//             admin,
//             challenges: table::new(ctx),
//             categories: vec_map::empty(),
//             pending_submissions: table::new(ctx),
//         });
//     }

//     // 提交新题目（待审核）
//     public entry fun submit_challenge(
//         category: vector<u8>,
//         title: vector<u8>,
//         description: vector<u8>,
//         points: u64,
//         cost_coins: u64,
//         reward_coins: u64,
//         list: &mut ChallengeList,
//         ctx: &mut TxContext
//     ) {
//         let challenge_id = table::length(&list.challenges) + table::length(&list.pending_submissions);
//         let challenge = Challenge {
//             id: object::new(ctx),
//             challenge_id,
//             category: string::utf8(category),      // 转换为String
//             title: string::utf8(title),
//             description: string::utf8(description),
//             points,
//             cost_coins,
//             reward_coins,
//             first_blood_reward: 0,      // 默认0，待审核时设置
//             second_blood_reward: 0,
//             third_blood_reward: 0,
//             solved_count: 0,
//             solvers: vec_set::empty(),
//             first_blood: option::none(),
//             second_blood: option::none(),
//             third_blood: option::none(),
//             is_published: false,
//         };

//         table::add(&mut list.pending_submissions, challenge_id, challenge);
//         event::emit(ChallengeSubmitted {
//             challenge_id,
//             submitter: tx_context::sender(ctx),
//             category: challenge.category,
//             title: challenge.title,
//         });
//     }

//     // 发布题目（仅管理员，设置一二三血奖励）
//     public entry fun publish_challenge(
//         admin: &AdminCap,
//         challenge_id: u64,
//         first_blood_reward: u64,
//         second_blood_reward: u64,
//         third_blood_reward: u64,
//         list: &mut ChallengeList,
//         ctx: &mut TxContext
//     ) {
//         assert!(tx_context::sender(ctx) == list.admin, EINVALID_ADMIN); // 确保调用者是管理员
//         assert!(table::contains(&list.pending_submissions, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在

//         let challenge = table::remove(&mut list.pending_submissions, challenge_id);
//         challenge.is_published = true;
//         challenge.first_blood_reward = first_blood_reward;
//         challenge.second_blood_reward = second_blood_reward;
//         challenge.third_blood_reward = third_blood_reward;

//         // 添加到分类
//         if (vec_map::contains(&list.categories, &challenge.category)) {
//             let cat_challenges = vec_map::get_mut(&mut list.categories, &challenge.category);
//             vec_set::insert(cat_challenges, challenge_id);
//         } else {
//             let cat_challenges = vec_set::singleton(challenge_id);
//             vec_map::insert(&mut list.categories, challenge.category, cat_challenges);
//         };

//         table::add(&mut list.challenges, challenge_id, challenge);
//         event::emit(ChallengePublished {
//             challenge_id,
//             category: challenge.category,
//             title: challenge.title,
//         });
//     }

//     // 开启题目（消耗金币）
//     public entry fun open_challenge(
//         challenge_id: u64,
//         user_list: &mut UserList,
//         list: &mut ChallengeList,
//         ctx: &mut TxContext
//     ) {
//         let user_addr = tx_context::sender(ctx);
//         assert!(table::contains(&list.challenges, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在
//         let challenge = table::borrow(&list.challenges, challenge_id);
//         assert!(challenge.is_published, 0); // 确保题目已发布
//         assert!(!vec_set::contains(&challenge.solvers, &user_addr), EALREADY_SOLVED); // 确保用户未解决

//         let user = user::get_user_mut(user_list, user_addr);
//         assert!(user.coins >= challenge.cost_coins, EINSUFFICIENT_COINS); // 确保用户有足够金币
//         user.coins = user.coins - challenge.cost_coins;

//         event::emit(ChallengeOpened {
//             user: user_addr,
//             challenge_id,
//             cost_coins: challenge.cost_coins,
//         });
//     }

//     // 解决题目（包含一二三血奖励）
//     public entry fun solve_challenge(
//         challenge_id: u64,
//         user_list: &mut UserList,
//         list: &mut ChallengeList,
//         ctx: &mut TxContext
//     ) {
//         let user_addr = tx_context::sender(ctx);
//         assert!(table::contains(&list.challenges, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在
//         let challenge = table::borrow_mut(&mut list.challenges, challenge_id);
//         assert!(challenge.is_published, 0); // 确保题目已发布
//         assert!(!vec_set::contains(&challenge.solvers, &user_addr), EALREADY_SOLVED); // 确保用户未解决

//         // 更新用户
//         let user = user::get_user_mut(user_list, user_addr);
//         user.points = user.points + challenge.points;
//         user.coins = user.coins + challenge.reward_coins;

//         // 处理一二三血奖励
//         let mut blood_reward = 0;
//         let mut blood_rank = 0;
//         if (option::is_none(&challenge.first_blood)) {
//             challenge.first_blood = option::some(user_addr);
//             blood_reward = challenge.first_blood_reward;
//             blood_rank = 1;
//             user.coins = user.coins + blood_reward;
//         } else if (option::is_none(&challenge.second_blood)) {
//             challenge.second_blood = option::some(user_addr);
//             blood_reward = challenge.second_blood_reward;
//             blood_rank = 2;
//             user.coins = user.coins + blood_reward;
//         } else if (option::is_none(&challenge.third_blood)) {
//             challenge.third_blood = option::some(user_addr);
//             blood_reward = challenge.third_blood_reward;
//             blood_rank = 3;
//             user.coins = user.coins + blood_reward;
//         };

//         // 更新题目
//         vec_set::insert(&mut challenge.solvers, user_addr);
//         challenge.solved_count = challenge.solved_count + 1;

//         // 更新用户能力
//         user::record_ability(user_list, user_addr, challenge.category, challenge.points);

//         event::emit(ChallengeSolved {
//             user: user_addr,
//             challenge_id,
//             points: challenge.points,
//             reward_coins: challenge.reward_coins,
//             blood_reward,
//             blood_rank,
//         });
//     }

//     // 获取题目信息
//     public fun get_challenge_info(list: &ChallengeList, challenge_id: u64): (String, String, String, u64, u64, u64, u64, u64, u64, u64) {
//         assert!(table::contains(&list.challenges, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在
//         let challenge = table::borrow(&list.challenges, challenge_id);
//         (
//             challenge.category,
//             challenge.title,
//             challenge.description,
//             challenge.points,
//             challenge.cost_coins,
//             challenge.reward_coins,
//             challenge.first_blood_reward,
//             challenge.second_blood_reward,
//             challenge.third_blood_reward,
//             challenge.solved_count
//         )
//     }

//     // 按分类获取题目列表
//     public fun get_challenges_by_category(list: &ChallengeList, category: String): vector<u64> {
//         if (vec_map::contains(&list.categories, &category)) {
//             vec_set::into_keys(*vec_map::get(&list.categories, &category))
//         } else {
//             vector::empty()
//         }
//     }

//     // 检查题目是否存在
//     public fun challenge_exists(list: &ChallengeList, challenge_id: u64): bool {
//         table::contains(&list.challenges, challenge_id)
//     }

//     // 检查用户是否已解决题目
//     public fun has_solved(list: &ChallengeList, challenge_id: u64, user_addr: address): bool {
//         assert!(table::contains(&list.challenges, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在
//         let challenge = table::borrow(&list.challenges, challenge_id);
//         vec_set::contains(&challenge.solvers, &user_addr)
//     }

//     // 添加WriteUp（供writeup模块调用）
//     public entry fun add_writeup(
//         challenge_id: u64,
//         writeup_id: u64,
//         list: &mut ChallengeList,
//         ctx: &mut TxContext
//     ) {
//         assert!(table::contains(&list.challenges, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在
//         let challenge = table::borrow_mut(&mut list.challenges, challenge_id);
//         vec_set::insert(&mut challenge.writeups, writeup_id);
//     }
// }
