// module letsmovectf::pyth {
//     use pyth::i64;
//     use pyth::price;
//     use pyth::price_identifier;
//     use pyth::price_info::{Self, PriceInfoObject};
//     use pyth::pyth;
//     use sui::clock::Clock;
//
//     const E_INVALID_ID: u64 = 1;
//
//     public fun use_pyth_price(clock: &Clock, price_info_object: &PriceInfoObject): u64 {
//         let max_age = 60;
//         // Make sure the price is not older than max_age seconds
//         let price_struct = pyth::get_price_no_older_than(price_info_object, clock, max_age);
//
//         // Check the price feed ID
//         let price_info = price_info::get_price_info_from_price_info_object(price_info_object);
//         let price_id = price_identifier::get_bytes(&price_info::get_price_identifier(&price_info));
//
//         // SUI/USD price feed ID
//         assert!(
//             price_id==x"50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266",
//             E_INVALID_ID,
//         );
//
//         // Get SUI/USD price and return
//         let price_i64 = price::get_price(&price_struct);
//         i64::get_magnitude_if_positive(&price_i64)
//     }
// }