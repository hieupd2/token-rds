#[test_only]
module token_rds::init_tests;

use sui::test_scenario::{Self as ts};
use sui::coin::{Self, TreasuryCap, CoinMetadata};
use token_rds::rds::{Self, RDS};
use std::ascii;
use std::string;

#[test]
fun test_init_creates_currency_with_correct_metadata() {
    let mut scenario = ts::begin(@0x1);
    
    // Test the init function
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, @0x1);
    
    // Check that metadata was created and frozen
    let metadata = ts::take_immutable<CoinMetadata<RDS>>(&scenario);
    
    // Verify metadata properties
    assert!(coin::get_decimals(&metadata) == 8, 0);
    assert!(coin::get_symbol(&metadata) == ascii::string(b"RDS"), 1);
    assert!(coin::get_name(&metadata) == string::utf8(b"RDS ON SUI"), 2);
    assert!(coin::get_description(&metadata) == string::utf8(b"RDS Taught Sui. Here's proof"), 3);
    
    // Check that icon URL was set
    assert!(coin::get_icon_url(&metadata).is_some(), 4);
    
    ts::return_immutable(metadata);
    ts::end(scenario);
}

#[test]
fun test_init_mints_correct_initial_supply() {
    let mut scenario = ts::begin(@0x1);
    
    // Test the init function
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, @0x1);
    
    // Check that initial coins were minted to sender
    let coin = ts::take_from_sender<coin::Coin<RDS>>(&scenario);
    
    // Expected: 1,000,000 * 10^8 = 100,000,000,000,000
    let expected_value = 100000000000000;
    assert!(coin::value(&coin) == expected_value, 0);
    
    ts::return_to_sender(&scenario, coin);
    ts::end(scenario);
}

#[test]
fun test_init_freezes_treasury_cap() {
    let mut scenario = ts::begin(@0x1);
    
    // Test the init function
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, @0x1);
    
    // Try to take treasury cap - should be frozen (immutable)
    let treasury_cap = ts::take_immutable<TreasuryCap<RDS>>(&scenario);
    
    // If we can take it as immutable, it means it was properly frozen
    ts::return_immutable(treasury_cap);
    ts::end(scenario);
}

#[test]
fun test_init_creates_all_required_objects() {
    let mut scenario = ts::begin(@0x1);
    
    // Test the init function
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, @0x1);
    
    // Check that all expected objects exist
    assert!(ts::has_most_recent_immutable<CoinMetadata<RDS>>(), 0);
    assert!(ts::has_most_recent_immutable<TreasuryCap<RDS>>(), 1);
    assert!(ts::has_most_recent_for_sender<coin::Coin<RDS>>(&scenario), 2);
    
    ts::end(scenario);
}

#[test]
fun test_init_with_different_sender() {
    let sender = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Test the init function with different sender
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    
    // Check that coins were sent to the correct sender
    let coin = ts::take_from_sender<coin::Coin<RDS>>(&scenario);
    assert!(coin::value(&coin) == 100000000000000, 0);
    
    ts::return_to_sender(&scenario, coin);
    ts::end(scenario);
}
