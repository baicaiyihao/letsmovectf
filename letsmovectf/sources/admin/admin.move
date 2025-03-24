module letsmovectf::admin{
    use sui::transfer::{ transfer };

    public struct AdminCap has key {
        id: UID,
    }

    fun init(ctx: &mut TxContext){
        transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
    }

    public fun mint_admincap(_admin: &AdminCap,to: address, ctx: &mut TxContext){
        transfer(AdminCap { id: object::new(ctx) }, to);
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext){
        init(ctx);
    }
}