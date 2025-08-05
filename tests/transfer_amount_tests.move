#[test_only]
module token_rds::transfer_amount_tests;

use sui::test_scenario::{Self as ts};
use sui::coin::{Self, Coin};
use token_rds::rds::{Self, RDS};

#[test]
fun test_transfer_amount_partial_balance() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with enough balance
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Transfer 600 units
        rds::transfer_amount(test_coin, 600, recipient, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        // Verify: sender received remaining 400 units
        let remaining_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&remaining_coin) == 400, 1);
        ts::return_to_sender(&scenario, remaining_coin);
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received 600 units
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 600, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_amount_full_balance() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with 1000 units
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Transfer all 1000 units
        rds::transfer_amount(test_coin, 1000, recipient, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received all 1000 units
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 1000, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_amount_minimum_amount() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with 100 units
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 100, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Transfer 1 unit (minimum)
        rds::transfer_amount(test_coin, 1, recipient, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        // Verify: sender received remaining 99 units
        let remaining_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&remaining_coin) == 99, 1);
        ts::return_to_sender(&scenario, remaining_coin);
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received 1 unit
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 1, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = token_rds::rds::E_AMOUNT_ZERO)]
fun test_transfer_amount_zero_amount_fails() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // This should fail with E_AMOUNT_ZERO
        rds::transfer_amount(test_coin, 0, recipient, ts::ctx(&mut scenario));
    };
    
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = token_rds::rds::E_INSUFFICIENT)]
fun test_transfer_amount_insufficient_balance_fails() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with 1000 units
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // This should fail with E_INSUFFICIENT (trying to transfer 1001 > 1000)
        rds::transfer_amount(test_coin, 1001, recipient, ts::ctx(&mut scenario));
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_amount_to_self() {
    let sender = @0x1;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with 1000 units
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Transfer 300 units to self
        rds::transfer_amount(test_coin, 300, sender, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        // Verify: sender should have received both the transferred amount and remainder
        // Due to the nature of the function, sender gets two separate coin objects
        let coins = ts::ids_for_address<Coin<RDS>>(sender);
        assert!(vector::length(&coins) >= 2, 0); // At least 2 coins (original + transfer result)
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_amount_large_amounts() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: use initial coins from init (1M tokens * 10^8)
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        
        // Transfer a large amount (500K * 10^8)
        let large_amount = 50000000000000; // 500,000 * 10^8
        rds::transfer_amount(coin, large_amount, recipient, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        // Verify: sender received remainder
        let remaining_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&remaining_coin) == 100000000000000 - 50000000000000, 1);
        ts::return_to_sender(&scenario, remaining_coin);
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received correct amount
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 50000000000000, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_amount_multiple_sequential_transfers() {
    let sender = @0x1;
    let recipient1 = @0x2;
    let recipient2 = @0x3;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with enough balance
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1000, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // First transfer: 300 units to recipient1
        rds::transfer_amount(test_coin, 300, recipient1, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        let remaining_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        
        // Second transfer: 200 units to recipient2
        rds::transfer_amount(remaining_coin, 200, recipient2, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, sender);
    {
        // Verify: sender received final remainder (1000 - 300 - 200 = 500)
        let final_remaining = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&final_remaining) == 500, 2);
        ts::return_to_sender(&scenario, final_remaining);
    };
    
    ts::next_tx(&mut scenario, recipient1);
    {
        // Verify: recipient1 received 300 units
        let coin1 = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&coin1) == 300, 0);
        ts::return_to_sender(&scenario, coin1);
    };
    
    ts::next_tx(&mut scenario, recipient2);
    {
        // Verify: recipient2 received 200 units
        let coin2 = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&coin2) == 200, 1);
        ts::return_to_sender(&scenario, coin2);
    };
    
    ts::end(scenario);
}

#[test]
fun test_transfer_amount_exact_edge_cases() {
    let sender = @0x1;
    let recipient = @0x2;
    let mut scenario = ts::begin(sender);
    
    // Setup: create coin with exactly 1 unit
    rds::init_for_testing(ts::ctx(&mut scenario));
    
    ts::next_tx(&mut scenario, sender);
    {
        let mut original_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        let test_coin = coin::split(&mut original_coin, 1, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, original_coin);
        
        // Transfer exactly 1 unit (full balance)
        rds::transfer_amount(test_coin, 1, recipient, ts::ctx(&mut scenario));
    };
    
    ts::next_tx(&mut scenario, recipient);
    {
        // Verify: recipient received the 1 unit
        let received_coin = ts::take_from_sender<Coin<RDS>>(&scenario);
        assert!(coin::value(&received_coin) == 1, 0);
        ts::return_to_sender(&scenario, received_coin);
    };
    
    ts::end(scenario);
}
