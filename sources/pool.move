module lending_pool::pool {
  use sui::id::VersionedID;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self, Coin, TreasuryCap};
  use sui::sui::SUI;

  struct LendingPool has key {
    id: VersionedID,
    owner: address,
    balance: Coin<SUI>,
  }

  // Check balance of pool
  public fun pool_balance(pool: &LendingPool): u64 {
    coin::value(&pool.balance)
  }

  struct POOLCOIN has drop {}

  // Deposit funds into the pool
  public entry fun deposit(pool: &mut LendingPool, depositor: Coin<SUI>, amount: u64, treasury_cap: &mut TreasuryCap<POOLCOIN>, ctx: &mut TxContext) {
    // Deduct deposit amount from user balance
    let user_balance = coin::balance_mut(&mut depositor);
    let deposit = coin::take(user_balance, amount, ctx);
    coin::keep(depositor, ctx);
    // Increase pool balance
    coin::join(&mut pool.balance, deposit);
    // Send pool tokens representing collateral to depositor
    coin::mint_and_transfer<POOLCOIN>(treasury_cap, amount, tx_context::sender(ctx), ctx);
  }

  // Withdraw funds
  public entry fun withdraw(pool: &mut LendingPool, collateral: Coin<POOLCOIN>, balance: Coin<SUI>, amount: u64, treasury_cap: &mut TreasuryCap<POOLCOIN>, ctx: &mut TxContext) {
    assert!(amount > 0, 0);
    // Reduce user's POOLCOIN balance
    let collateral_balance = coin::balance_mut(&mut collateral);
    let withdrawal_amount = coin::take(collateral_balance, amount, ctx);
    // Burn POOLCOINs
    coin::burn(treasury_cap, withdrawal_amount);
    coin::keep(collateral, ctx);
    // Reduce pool's SUI balance
    let pool_bal = coin::balance_mut(&mut pool.balance);
    // Send withdrawn coins to user
    let withdrawal = coin::take(pool_bal, amount, ctx);
    let user_balance = coin::balance_mut(&mut balance);
    coin::put(user_balance, withdrawal);
    coin::keep(balance, ctx);
  }

  // Create a pool
  fun init(ctx: &mut TxContext) {
    transfer::share_object(LendingPool {
      id: tx_context::new_id(ctx),
      owner: tx_context::sender(ctx),
      balance: coin::zero<SUI>(ctx)
    });
    let treasury_cap = coin::create_currency<POOLCOIN>(POOLCOIN{}, ctx);
    transfer::share_object(treasury_cap);
  }

  #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
  }
}
