module letsmovectf::checkAcount;
use std::ascii::String;
use sui::clock::Clock;
use sui::table;
use sui::table::{Table};
use sui::transfer::share_object;
use sui::clock;
use sui::event::emit;

const EUSER_NOT_FOUND: u64 = 1;



public struct UnCheckUserList has key, store{
    id:UID,
    users:Table<address,u64> //useraddress create time
}

//Event uncheck user create.
public struct UserChecked has drop,copy{
    useraddress:address,
    result:bool,
    reason:Option<String>,
    checktime:u64,
}


public(package) fun create_event(
    useraddress:address,
    result:bool,
    reason:Option<String>,
    clock:&Clock
){
    emit(UserChecked{
        useraddress,
        result,
        reason,
        checktime:clock::timestamp_ms(clock)
    })
}

//create uncheck user table
public(package) fun new_uncheck_list(
    ctx:&mut TxContext
){
    share_object(UnCheckUserList{
        id:object::new(ctx),
        users:table::new(ctx)
    });
}


//when user checked ,table remove it.
public(package) fun remove_uncheck_user(
    address:address,
    table:&mut UnCheckUserList
){
    assert!(table::contains(&table.users,address),EUSER_NOT_FOUND);
    let _ =table::remove(&mut table.users,address);
}

//when user create add it.
public(package) fun addUncheckUser(
    unchecklist:&mut UnCheckUserList,
    userAddress:address,
    clock:&Clock
){
    table::add(&mut unchecklist.users,userAddress,clock::timestamp_ms(clock));
}
