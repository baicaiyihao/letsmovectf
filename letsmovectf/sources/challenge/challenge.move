module letsmovectf::challenge;
use std::option::is_none;
use std::string::{String};
use letsmovectf::user::{UserList, is_check_user};
use sui::balance;
use letsmovectf::admin::AdminCap;
use sui::balance::Balance;
use sui::balance::{join as join_balance,split as split_balance};
use sui::coin::{Coin, into_balance, from_balance};
use sui::table;
use sui::table::Table;
use sui::transfer::{share_object, public_transfer};
use sui::tx_context::sender;
use sui::vec_set;
use sui::vec_set::{VecSet, empty};


public struct Challenge has key,store{
            id: UID,
            challenge_id: String,              // 唯一题目ID
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
            other_blood_reward: u64,        //普通用户解题金币
            solved_count: u64,              // 已解决人数
            solvers: VecSet<address>,       // 解决者列表
            first_blood: Option<address>,   // 一血用户
            second_blood: Option<address>,  // 二血用户
            third_blood: Option<address>,   // 三血用户
            is_published: bool,             // 题目是否已发布
}

public struct ChallengeTable has key{
    id:UID,
    challenge:Table<String,Challenge> //challenge_id ,Challenge
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
    challenge_id: String,              // 唯一题目ID
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
    other_blood_reward:u64,         // 普通用户奖励金币
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
        other_blood_reward,
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

public(package) fun add_solvers(
    challengetable:&mut ChallengeTable,
    useraddress:address,
    challengeId:String
){
    let mut challenge = table::borrow_mut(&mut challengetable.challenge,challengeId);
    challenge.solved_count=challenge.solved_count+1;
    vec_set::insert(&mut challenge.solvers,useraddress);
}

public entry fun send_flag_reward<FLag>(
    _admin:&AdminCap,
    flagPool:&mut FlagAccount<FLag>,
    userAddress:Option<address>,
    userAddress1:address,
    userlist:&UserList,
    challenge:&mut ChallengeTable,
    challenge_id:String,
    ctx:&mut TxContext,
){
    // assert!();
    is_check_user(userlist,userAddress1);
    let challenge1 = table::borrow(&challenge.challenge,challenge_id);
    if(is_none(&challenge1.first_blood)){
        let flag_balance = split_balance(&mut flagPool.flag_coin,challenge1.first_blood_reward);
        let flag_coin = from_balance(flag_balance,ctx);
        let  challenge2=table::borrow_mut(&mut challenge.challenge,challenge_id);
        challenge2.first_blood=userAddress;
        public_transfer(flag_coin,userAddress1);
        add_solvers(challenge,userAddress1,challenge_id);
        return;
    };
    if(is_none(&challenge1.second_blood)){
        let flag_balance = split_balance(&mut flagPool.flag_coin,challenge1.second_blood_reward);
        let flag_coin = from_balance(flag_balance,ctx);
        let  challenge2=table::borrow_mut(&mut challenge.challenge,challenge_id);
        challenge2.second_blood=userAddress;
        public_transfer(flag_coin,userAddress1);
        add_solvers(challenge,userAddress1,challenge_id);
        return;
    };
    if(is_none(&challenge1.third_blood)){
        let flag_balance = split_balance(&mut flagPool.flag_coin,challenge1.third_blood_reward);
        let flag_coin = from_balance(flag_balance,ctx);
        let  challenge2=table::borrow_mut(&mut challenge.challenge,challenge_id);
        challenge2.third_blood=userAddress;
        public_transfer(flag_coin,userAddress1);
        add_solvers(challenge,userAddress1,challenge_id);
        return;
    };
    let flag_balance = split_balance(&mut flagPool.flag_coin,challenge1.other_blood_reward);
    let flag_coin = from_balance(flag_balance,ctx);
    public_transfer(flag_coin,userAddress1);
    add_solvers(challenge,userAddress1,challenge_id);
}

