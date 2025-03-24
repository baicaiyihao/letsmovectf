// module letsmovectf::writeup {
//     use sui::object::{Self, UID};
//     use sui::tx_context::{Self, TxContext};
//     use sui::transfer;
//     use sui::table::{Self, Table};
//     use sui::event;
//     use sui::vec_set::{Self, VecSet};
//     use letsmovectf::admin::AdminCap;
//     use letsmovectf::user::{Self, UserList};
//     use letsmovectf::challenge::{Self, ChallengeList};

//     // 错误码
//     const EWRITEUP_NOT_FOUND: u64 = 1;      // WriteUp不存在
//     const EINVALID_ADMIN: u64 = 2;          // 无效的管理员
//     const EINSUFFICIENT_COINS: u64 = 3;     // 金币不足
//     const EINVALID_SUBMISSION: u64 = 4;     // 无效的提交
//     const EALREADY_PUBLISHED: u64 = 5;      // WriteUp已发布
//     const ECHALLENGE_NOT_FOUND: u64 = 6;    // 题目不存在

//     // WriteUp结构体
//     public struct WriteUp has key, store {
//         id: UID,
//         writeup_id: u64,                // 唯一WriteUp ID
//         challenge_id: u64,              // 关联的题目ID
//         author: address,                // 作者地址
//         content: vector<u8>,            // WriteUp内容（或IPFS哈希）
//         view_cost: u64,                 // 查看所需金币
//         earnings: u64,                  // 查看收益
//         is_published: bool,             // 是否已发布
//     }

//     // 全局WriteUp列表
//     public struct WriteUpList has key {
//         id: UID,
//         admin: address,                 // 管理员地址
//         writeups: Table<u64, WriteUp>,  // 已发布的WriteUp（ID -> WriteUp）
//         pending: Table<u64, WriteUp>,   // 待审核的WriteUp
//         drafts: Table<u64, WriteUp>,    // 草稿（被拒绝后保留）
//         writeup_count: u64,             // WriteUp总数
//     }

//     // 事件：WriteUp提交
//     public struct WriteUpSubmitted has copy, drop {
//         writeup_id: u64,
//         challenge_id: u64,
//         author: address,
//         view_cost: u64,
//     }

//     // 事件：WriteUp审核通过
//     public struct WriteUpPublished has copy, drop {
//         writeup_id: u64,
//         challenge_id: u64,
//         author: address,
//     }

//     // 事件：WriteUp被拒绝
//     public struct WriteUpRejected has copy, drop {
//         writeup_id: u64,
//         challenge_id: u64,
//         author: address,
//         reason: vector<u8>,             // 拒绝理由
//     }

//     // 事件：WriteUp被查看
//     public struct WriteUpViewed has copy, drop {
//         viewer: address,
//         writeup_id: u64,
//         author: address,
//         cost: u64,
//     }

//     // 事件：WriteUp保存为草稿
//     public struct WriteUpSavedAsDraft has copy, drop {
//         writeup_id: u64,
//         challenge_id: u64,
//         author: address,
//     }

//     // 初始化WriteUpList
//     fun init(ctx: &mut TxContext) {
//         let admin = tx_context::sender(ctx);
//         transfer::share_object(WriteUpList {
//             id: object::new(ctx),
//             admin,
//             writeups: table::new(ctx),
//             pending: table::new(ctx),
//             drafts: table::new(ctx),
//             writeup_count: 0,
//         });
//     }

//     // 提交WriteUp（待审核）
//     public entry fun submit_writeup(
//         challenge_id: u64,
//         content: vector<u8>,
//         view_cost: u64,
//         user_list: &mut UserList,
//         challenge_list: &ChallengeList,
//         list: &mut WriteUpList,
//         ctx: &mut TxContext
//     ) {
//         let user_addr = tx_context::sender(ctx);
//         assert!(challenge::challenge_exists(challenge_list, challenge_id), ECHALLENGE_NOT_FOUND); // 确保题目存在
//         assert!(challenge::has_solved(challenge_list, challenge_id, user_addr), EINVALID_SUBMISSION); // 确保用户已解决题目

//         let writeup_id = list.writeup_count;
//         list.writeup_count = list.writeup_count + 1;

//         let writeup = WriteUp {
//             id: object::new(ctx),
//             writeup_id,
//             challenge_id,
//             author: user_addr,
//             content,
//             view_cost,
//             earnings: 0,
//             is_published: false,
//         };

//         table::add(&mut list.pending, writeup_id, writeup);
//         user::record_writeup(user_list, user_addr, writeup_id);

//         event::emit(WriteUpSubmitted {
//             writeup_id,
//             challenge_id,
//             author: user_addr,
//             view_cost,
//         });
//     }

//     // 审核WriteUp（通过）
//     public entry fun approve_writeup(
//         admin: &AdminCap,
//         writeup_id: u64,
//         challenge_list: &mut ChallengeList,
//         list: &mut WriteUpList,
//         ctx: &mut TxContext
//     ) {
//         assert!(tx_context::sender(ctx) == list.admin, EINVALID_ADMIN); // 确保调用者是管理员
//         assert!(table::contains(&list.pending, writeup_id), EWRITEUP_NOT_FOUND); // 确保WriteUp存在

//         let writeup = table::remove(&mut list.pending, writeup_id);
//         writeup.is_published = true;

//         let challenge_id = writeup.challenge_id;
//         challenge::add_writeup(challenge_list, challenge_id, writeup_id);

//         table::add(&mut list.writeups, writeup_id, writeup);
//         transfer::share_object(writeup);

//         event::emit(WriteUpPublished {
//             writeup_id,
//             challenge_id,
//             author: writeup.author,
//         });
//     }

//     // 审核WriteUp（拒绝）
//     public entry fun reject_writeup(
//         admin: &AdminCap,
//         writeup_id: u64,
//         reason: vector<u8>,
//         list: &mut WriteUpList,
//         ctx: &mut TxContext
//     ) {
//         assert!(tx_context::sender(ctx) == list.admin, EINVALID_ADMIN); // 确保调用者是管理员
//         assert!(table::contains(&list.pending, writeup_id), EWRITEUP_NOT_FOUND); // 确保WriteUp存在

//         let writeup = table::remove(&mut list.pending, writeup_id);
//         let challenge_id = writeup.challenge_id;
//         let author = writeup.author;

//         // 移动到草稿表
//         table::add(&mut list.drafts, writeup_id, writeup);

//         event::emit(WriteUpRejected {
//             writeup_id,
//             challenge_id,
//             author,
//             reason,
//         });
//     }

//     // 用户选择将拒绝的WriteUp保存为草稿（可选）
//     public entry fun save_as_draft(
//         writeup_id: u64,
//         list: &mut WriteUpList,
//         ctx: &mut TxContext
//     ) {
//         let user_addr = tx_context::sender(ctx);
//         assert!(table::contains(&list.drafts, writeup_id), EWRITEUP_NOT_FOUND); // 确保WriteUp存在
//         let writeup = table::borrow(&list.drafts, writeup_id);
//         assert!(writeup.author == user_addr, 0); // 确保调用者是作者

//         event::emit(WriteUpSavedAsDraft {
//             writeup_id,
//             challenge_id: writeup.challenge_id,
//             author: user_addr,
//         });
//     }

//     // 从草稿重新提交WriteUp
//     public entry fun resubmit_writeup(
//         writeup_id: u64,
//         content: vector<u8>,
//         view_cost: u64,
//         user_list: &mut UserList,
//         list: &mut WriteUpList,
//         ctx: &mut TxContext
//     ) {
//         let user_addr = tx_context::sender(ctx);
//         assert!(table::contains(&list.drafts, writeup_id), EWRITEUP_NOT_FOUND); // 确保WriteUp存在
//         let writeup = table::remove(&mut list.drafts, writeup_id);
//         assert!(writeup.author == user_addr, 0); // 确保调用者是作者

//         // 更新内容和查看金币
//         writeup.content = content;
//         writeup.view_cost = view_cost;

//         table::add(&mut list.pending, writeup_id, writeup);
//         user::record_writeup(user_list, user_addr, writeup_id);

//         event::emit(WriteUpSubmitted {
//             writeup_id,
//             challenge_id: writeup.challenge_id,
//             author: user_addr,
//             view_cost,
//         });
//     }

//     // 查看WriteUp（支付金币）
//     public entry fun view_writeup(
//         writeup_id: u64,
//         writeup: &mut WriteUp,
//         user_list: &mut UserList,
//         ctx: &mut TxContext
//     ) {
//         let viewer = tx_context::sender(ctx);
//         assert!(writeup.writeup_id == writeup_id, 0); // 确保WriteUp ID匹配
//         assert!(writeup.is_published, 0); // 确保WriteUp已发布
//         assert!(viewer != writeup.author, 0); // 确保查看者不是作者

//         let viewer_user = user::get_user_mut(user_list, viewer);
//         assert!(viewer_user.coins >= writeup.view_cost, EINSUFFICIENT_COINS); // 确保查看者有足够金币

//         let author_user = user::get_user_mut(user_list, writeup.author);
//         viewer_user.coins = viewer_user.coins - writeup.view_cost;
//         author_user.coins = author_user.coins + writeup.view_cost;
//         writeup.earnings = writeup.earnings + writeup.view_cost;

//         event::emit(WriteUpViewed {
//             viewer,
//             writeup_id,
//             author: writeup.author,
//             cost: writeup.view_cost,
//         });
//     }

//     // 获取WriteUp信息
//     public fun get_writeup_info(writeup: &WriteUp): (u64, address, u64, u64, bool) {
//         (
//             writeup.challenge_id,
//             writeup.author,
//             writeup.view_cost,
//             writeup.earnings,
//             writeup.is_published
//         )
//     }

//     // 按题目ID获取WriteUp列表
//     public fun get_writeups_by_challenge(list: &WriteUpList, challenge_id: u64): vector<u64> {
//         let mut writeup_ids = vector::empty<u64>();
//         let iter = table::iter(&list.writeups);
//         while (table::iter_has_next(iter)) {
//             let (id, writeup) = table::iter_next(iter);
//             if (writeup.challenge_id == challenge_id && writeup.is_published) {
//                 vector::push_back(&mut writeup_ids, id);
//             }
//         };
//         writeup_ids
//     }

//     // 获取用户的草稿列表
//     public fun get_drafts_by_user(list: &WriteUpList, user_addr: address): vector<u64> {
//         let mut draft_ids = vector::empty<u64>();
//         let iter = table::iter(&list.drafts);
//         while (table::iter_has_next(iter)) {
//             let (id, writeup) = table::iter_next(iter);
//             if (writeup.author == user_addr) {
//                 vector::push_back(&mut draft_ids, id);
//             }
//         };
//         draft_ids
//     }
// }