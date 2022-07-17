#[test_only]

module lending_pool::pool_tests {
  use lending_pool::pool::{Self, LendingPool, POOLCOIN};
  use sui::test_scenario;
  use sui::balance::{Self};
  use sui::coin::{Self, Coin, TreasuryCap};
  use sui::sui::SUI;


  #[test]
  fun test_deposit(){
    let owner = @0x1;
    let depositor = @0x2;
    let scenario = &mut test_scenario::begin(&owner);

    // Initialize the lending pool
    test_scenario::next_tx(scenario, &owner);
    {
      let ctx = test_scenario::ctx(scenario);
      pool::init_for_testing(ctx);
    };

    // Give depositor 10 SUI
    test_scenario::next_tx(scenario, &depositor);
    {
      let ctx = test_scenario::ctx(scenario);
      let sui_coins = coin::mint_for_testing<SUI>(10, ctx);
      coin::keep(sui_coins, ctx);
    };

    // Ensure depositer has 10 SUI
    test_scenario::next_tx(scenario, &depositor);
    {
      let user_funds = test_scenario::take_owned<Coin<SUI>>(scenario);
      assert!(coin::value(&user_funds)==10,0);
      test_scenario::return_owned(scenario, user_funds);
    };

    // Deposit funds
    test_scenario::next_tx(scenario, &depositor);
    {
      // Take ownership
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      let treasury_wrapper = test_scenario::take_shared<TreasuryCap<POOLCOIN>>(scenario);
      let treasury_cap = test_scenario::borrow_mut(&mut treasury_wrapper);
      let coins = test_scenario::take_owned<Coin<SUI>>(scenario);
      // Deposit 10 tokens
      let ctx = test_scenario::ctx(scenario);
      pool::deposit(pool, coins, 10, treasury_cap, ctx);
      // Return ownership
      test_scenario::return_shared(scenario, pool_wrapper);
      test_scenario::return_shared(scenario, treasury_wrapper);
    };

    // Test user's SUI balance is 0 after deposit
    test_scenario::next_tx(scenario, &depositor);
    {
      let user_funds = test_scenario::take_owned<Coin<SUI>>(scenario);
      assert!(coin::value(&user_funds)==0,0);
      test_scenario::return_owned(scenario, user_funds);
    };

    // Test lending pool's SUI balance is 10 after deposit
    test_scenario::next_tx(scenario, &owner);
    {
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      assert!(pool::pool_balance(pool) == 10, 0);
      test_scenario::return_shared(scenario, pool_wrapper);
    };

    // Test depositor's POOLTOKEN balance is 10 after deposit
    test_scenario::next_tx(scenario, &depositor);
    {
      let tokens = test_scenario::take_owned<Coin<POOLCOIN>>(scenario);
      let user_balance = balance::value(coin::balance(&tokens));
      assert!(user_balance == 10, 0);
      test_scenario::return_owned(scenario, tokens);
    }
  }

  #[test]
  fun test_borrow(){
    let owner = @0x1;
    let borrower = @0x2;
    let scenario = &mut test_scenario::begin(&owner);

    // Initialize the lending pool
    test_scenario::next_tx(scenario, &owner);
    {
      let ctx = test_scenario::ctx(scenario);
      pool::init_for_testing(ctx);
    };

    // Give borrower some collateral
    test_scenario::next_tx(scenario, &borrower);
    {
      let ctx = test_scenario::ctx(scenario);
      let sui_coins = coin::mint_for_testing<SUI>(10, ctx);
      coin::keep(sui_coins, ctx);
    };
    test_scenario::next_tx(scenario, &borrower);
    {
      let user_funds = test_scenario::take_owned<Coin<SUI>>(scenario);
      assert!(coin::value(&user_funds)==10,0);
      test_scenario::return_owned(scenario, user_funds);
    };

    // Deposit collateral
    test_scenario::next_tx(scenario, &borrower);
    {
      // Take ownership
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      let treasury_wrapper = test_scenario::take_shared<TreasuryCap<POOLCOIN>>(scenario);
      let treasury_cap = test_scenario::borrow_mut(&mut treasury_wrapper);
      let coins = test_scenario::take_owned<Coin<SUI>>(scenario);
      // Deposit 10 tokens
      let ctx = test_scenario::ctx(scenario);
      pool::deposit(pool, coins, 10, treasury_cap, ctx);
      // Return ownership
      test_scenario::return_shared(scenario, pool_wrapper);
      test_scenario::return_shared(scenario, treasury_wrapper);
    };

    // Borrow funds
    test_scenario::next_tx(scenario, &borrower);
    {
      // Take ownership
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      let treasury_wrapper = test_scenario::take_shared<TreasuryCap<POOLCOIN>>(scenario);
      let treasury_cap = test_scenario::borrow_mut(&mut treasury_wrapper);
      let coins = test_scenario::take_owned<Coin<POOLCOIN>>(scenario);
      let sui_coins = test_scenario::take_owned<Coin<SUI>>(scenario);
      // Borrow 6 tokens
      let ctx = test_scenario::ctx(scenario);
      pool::borrow(pool, coins, sui_coins, 6, treasury_cap, ctx);
      // Return ownership
      test_scenario::return_shared(scenario, pool_wrapper);
      test_scenario::return_shared(scenario, treasury_wrapper);
    };

    // Test user's SUI balance is 6 after deposit
    test_scenario::next_tx(scenario, &borrower);
    {
      let user_funds = test_scenario::take_owned<Coin<SUI>>(scenario);
      assert!(coin::value(&user_funds)==6,0);
      test_scenario::return_owned(scenario, user_funds);
    };

    // Test user's POOLCOIN balance is 4 after borrow
    test_scenario::next_tx(scenario, &borrower);
    {
      let user_funds = test_scenario::take_owned<Coin<POOLCOIN>>(scenario);
      assert!(coin::value(&user_funds)==4,0);
      test_scenario::return_owned(scenario, user_funds);
    };
  }
}