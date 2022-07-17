#[test_only]

module lending_pool::pool_tests {
  use lending_pool::pool::{Self, LendingPool};
  use sui::test_scenario;
  use sui::coin::{Self};
  use sui::sui::SUI;

  #[test]
  fun test_deposit(){
    let owner = @0x1;
    let depositer = @0x2;
    let scenario = &mut test_scenario::begin(&owner);
    // Initialize the lending pool
    test_scenario::next_tx(scenario, &owner);
    {
      let ctx = test_scenario::ctx(scenario);
      pool::init_for_testing(ctx);
    };
    // Deposit funds - 10 SUI
    test_scenario::next_tx(scenario, &depositer);
    {
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      let ctx = test_scenario::ctx(scenario);
      pool::deposit(pool, coin::mint_for_testing<SUI>(10, ctx), ctx);
      test_scenario::return_shared(scenario, pool_wrapper);
    };
    // Test lending pool balance is equal to 10
    test_scenario::next_tx(scenario, &owner);
    {
      let pool_wrapper = test_scenario::take_shared<LendingPool>(scenario);
      let pool = test_scenario::borrow_mut(&mut pool_wrapper);
      assert!(pool::pool_balance(pool) == 10, 0);
      test_scenario::return_shared(scenario, pool_wrapper);
    }
  }
}