#[test_only]

module lending_pool::pool_tests {
  use lending_pool::pool::{Self, LendingPool, POOLCOIN};
  use sui::test_scenario;
  use sui::balance;
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
    // Deposit funds - 10 SUI.
    test_scenario::next_tx(scenario, &owner);
    {
      // Take ownership of the pool
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      // Take ownership of the treasury capacity
      let treasury_cap = test_scenario::take_owned<TreasuryCap<POOLCOIN>>(scenario);
      // Mint SUI coins
      let ctx = test_scenario::ctx(scenario);
      let sui_coins = coin::mint_for_testing<SUI>(10, ctx);
      // Deposit into the pool
      pool::deposit(pool, depositor, sui_coins, &mut treasury_cap, ctx);
      // Return ownership
      test_scenario::return_shared(scenario, pool_wrapper);
      test_scenario::return_owned(scenario, treasury_cap);
    };
    // Test lending pool balance is equal to 10
    test_scenario::next_tx(scenario, &owner);
    {
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      assert!(pool::pool_balance(pool) == 10, 0);
      test_scenario::return_shared(scenario, pool_wrapper);
    };
    // Test depositor POOLTOKEN balance is equal to 10
    test_scenario::next_tx(scenario, &depositor);
    {
      let tokens = test_scenario::take_owned<Coin<POOLCOIN>>(scenario);
      let user_balance = balance::value(coin::balance(&tokens));
      assert!(user_balance == 10, 0);
      test_scenario::return_owned(scenario, tokens);
    }
  }
}