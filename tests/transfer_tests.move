#[test_only]
module token_rds::transfer_tests;

use sui::test_scenario::{Self as ts};
use sui::coin::{Self, Coin};
use token_rds::rds::{Self, RDS};

#[test]
fun test_transfer_basic_functionality() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coins
    ts::next_tx(&mut scenario, sender);
    {
        rds::init_for_testing(ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        
        // Split a portion for testing
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Execute transfer
        rds::transfer(test_coin, recipient);
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received the coin
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 1000, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_full_balance() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: get initial coins from init
    ts::next_tx(&mut scenario, sender);
    {
        rds::init_for_testing(ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        let coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        
        // Execute transfer of full balance
        rds::transfer(coin, recipient);
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received all coins
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 100000000000000, 0); // 1M * 10^8
        ts::return_to_sender(&scenario, received_coin);
    };
    
    // Verify: sender has no coins left
    assert!(!ts::has_most_recent_for_sender<Coin<RDS>>(&scenario), 1);
    
    ts::end(scenario);
}

#[test]
fun test_transfer_small_amount() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with small amount
    ts::next_tx(&mut scenario, sender);
    {
        rds::init_for_testing(ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        
        // Split a very small amount for testing
        let test_coin = coin::split(&mut original_coin, 1, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        assert!(coin::value(&test_coin) == 1, 0);
        
        // Transfer the small coin
        rds::transfer(test_coin, recipient);
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received the small coin
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 1, 1);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_to_same_address() {
    let sender = @0x1;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coins
    ts::next_tx(&mut scenario, sender);
    {
        rds::init_for_testing(ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Execute transfer to self
        rds::transfer(test_coin, sender);
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        // Verify: sender received the coin back
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 1000, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_multiple_transactions() {
    let sender = @0x1;
    let recipient1 = @0x2;
    let recipient2 = @0x3;
    let mut scenario = ts::begin(sender);
    
    // Setup: create multiple coins
    ts::next_tx(&mut scenario, sender);
    {
        rds::init_for_testing(ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut all_coins = ts::take_from_sender<Coin<RDS>>(&scenario);
        
        // Split into multiple coins
        let coin1 = coin::split(&mut all_coins, 1000, ts::ctx(&mut scenario));
        let coin2 = coin::split(&mut all_coins, 2000, ts::ctx(&mut scenario));
        
        ts::return_to_sender(&scenario, all_coins);
        
        // Transfer first coin
        rds::transfer(coin1, recipient1);
        
        // Transfer second coin
        rds::transfer(coin2, recipient2);
    };
    
    ts::next_tx(&mut scenario, recipient1);
    {
        // Verify first transfer
        let received_coin1 = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin1) == 1000, 0);
        ts::return_to_sender(&scenario, received_coin1);
    };
    
    ts::next_tx(&mut scenario, recipient2);
    {
        // Verify second transfer
        let received_coin2 = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin2) == 2000, 1);
        ts::return_to_sender(&scenario, received_coin2);
    };
    
    ts::end(scenario);
}
