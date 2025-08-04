/*
/// Module: token_rds
module token_rds::token_rds;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module token_rds::rds;

use sui::coin::{Self, Coin};
use sui::url;

#[error]
const E_AMOUNT_ZERO: vector<u8> = b"Zero Amount";

#[error]
const E_INSUFFICIENT: vector<u8> = b"Insufficient Amount";

public struct RDS has drop {}

fun init(otw: RDS, ctx: &mut TxContext) {
    // Create the icon URL
    let icon_url = url::new_unsafe_from_bytes(b"https://framerusercontent.com/images/0KKocValgAmB9XHzcFI6tALxGGQ.jpg");
    let decimals: u8 = 8;
 
    // Fixed multiplier for 8 decimals (10^8)
    let multiplier = 100000000; // 10^8
 
    // Create the currency - make treasury mutable
    let (mut treasuryCap, metadata) = coin::create_currency(
        otw,
        decimals,
        b"RDS",
        b"RDS ON SUI",
        b"RDS Taught Sui. Here's proof",
        option::some(icon_url),
        ctx,
    );
 
    // Mint 1m tokens (1m * 10^8 base units)
    let initial_coins = coin::mint(&mut treasuryCap, 1000000 * multiplier, ctx);
    transfer::public_transfer(initial_coins, tx_context::sender(ctx));
 
    transfer::public_freeze_object(metadata);
    transfer::public_freeze_object(treasuryCap);
}

public entry fun transfer(c: Coin<RDS>, recipient: address) {
    transfer::public_transfer(c, recipient);
}

public entry fun transfer_amount(
    mut c: Coin<RDS>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {

    assert!(amount > 0, E_AMOUNT_ZERO);

    let bal = coin::value<RDS>(&c);
    assert!(amount <= bal, E_INSUFFICIENT);

    if (amount == bal) {
        transfer::public_transfer(c, recipient);
        return
    };

    let to_send = coin::split<RDS>(&mut c, amount, ctx);
    transfer::public_transfer(to_send, recipient);
    transfer::public_transfer(c, tx_context::sender(ctx));
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(RDS {}, ctx);
}