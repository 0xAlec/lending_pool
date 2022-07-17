module lending_pool::pool {
  use sui::id::VersionedID;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self, Coin};
  use sui::sui::SUI;
  use sui::balance::{Self, Balance};

  struct LendingPool has key {
    id: VersionedID,
    // owner
    owner: address,
    // balance
    balance: Balance<SUI>,
  }

  // See balance of pool
  public fun pool_balance(pool: &LendingPool): u64 {
    balance::value(&pool.balance)
  }

  struct UserRecord has key {
    id: VersionedID,
    // user
    owner: address,
    // deposits
    deposits: u128,
    // borrowed
    borrows: u128,
  }

  // Create a pool
  fun init(ctx: &mut TxContext) {
    transfer::share_object(LendingPool {
      id: tx_context::new_id(ctx),
      owner: tx_context::sender(ctx),
      balance: balance::zero<SUI>()
    })
  }

  #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
  }

  // Deposit funds
  public entry fun deposit(pool: &mut LendingPool, amount: Coin<SUI>, _ctx: &mut TxContext) {
    let b = coin::into_balance(amount);
    balance::join(&mut pool.balance, b);
    // let depositor = tx_context::sender(_ctx);
  }
}