// An AAVE-like lending pool implementation,
// mint POOLCOINs representing collateral (currently taking deposits in SUI)
// borrow SUI by burning POOLCOINs and minting DEBTCOINs

module lending_pool::pool {
  use sui::id::VersionedID;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self, Coin, TreasuryCap};
  use sui::sui::SUI;

  struct POOLCOIN has drop {}
  struct DEBTCOIN has drop {}

  struct LendingPool has key {
    id: VersionedID,
    lp_cap: TreasuryCap<POOLCOIN>,
    debt_cap: TreasuryCap<DEBTCOIN>,
    owner: address,
    balance: Coin<SUI>,
  }

  fun init(ctx: &mut TxContext) {
    let id = tx_context::new_id(ctx);
    let owner = tx_context::sender(ctx);
    let balance = coin::zero<SUI>(ctx);
    let lp_cap = coin::create_currency<POOLCOIN>(POOLCOIN{}, ctx);
    let debt_cap = coin::create_currency<DEBTCOIN>(DEBTCOIN{}, ctx);
    transfer::share_object(LendingPool{ id, owner, balance, lp_cap, debt_cap });
  }

  /// === Writes ===

  // Deposit funds into the pool
  public entry fun deposit(pool: &mut LendingPool, depositor: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    // Deduct deposit amount from user balance
    let user_balance = coin::balance_mut(&mut depositor);
    let deposit = coin::take(user_balance, amount, ctx);
    coin::keep(depositor, ctx);
    // Increase pool balance
    coin::join(&mut pool.balance, deposit);
    // Send pool tokens representing collateral to depositor
    coin::mint_and_transfer<POOLCOIN>(&mut pool.lp_cap, amount, tx_context::sender(ctx), ctx);
  }

  // Withdraw collateral
  public entry fun withdraw(pool: &mut LendingPool, collateral: Coin<POOLCOIN>, balance: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
    assert!(amount > 0, 0);
    // Reduce user's POOLCOIN balance
    let collateral_balance = coin::balance_mut(&mut collateral);
    let withdrawn_collateral = coin::take(collateral_balance, amount, ctx);
    // Burn POOLCOINs
    coin::burn(&mut pool.lp_cap, withdrawn_collateral);
    coin::keep(collateral, ctx);
    // Reduce pool's SUI balance
    let pool_bal = coin::balance_mut(&mut pool.balance);
    // Send withdrawn coins to user
    let withdrawal = coin::take(pool_bal, amount, ctx);
    let user_balance = coin::balance_mut(&mut balance);
    coin::put(user_balance, withdrawal);
    coin::keep(balance, ctx);
  }

  // Borrow coins
  public entry fun borrow(pool: &mut LendingPool, collateral: Coin<POOLCOIN>, balance: Coin<SUI>, amount: u64, ctx: &mut TxContext){
    assert!(amount >0, 0);
    // Ex: LTV 50%
    let borrow_balance = coin::balance_mut(&mut collateral);
    let borrow_coins = coin::take(borrow_balance, 2*amount, ctx);
    // Burn POOLCOINs
    coin::burn(&mut pool.lp_cap, borrow_coins);
    coin::keep(collateral, ctx);
    // Reduce pool's SUI balance
    let pool_bal = coin::balance_mut(&mut pool.balance);
    // Send withdrawn coins to user
    let withdrawal = coin::take(pool_bal, amount, ctx);
    let user_balance = coin::balance_mut(&mut balance);
    coin::put(user_balance, withdrawal);
    coin::keep(balance, ctx);
    // Mint debt tokens
    coin::mint_and_transfer<DEBTCOIN>(&mut pool.debt_cap, amount, tx_context::sender(ctx), ctx);
  }

  // Repay borrowed funds 
  public entry fun repay(pool: &mut LendingPool, coin: Coin<SUI>, debt_coin: Coin<DEBTCOIN>, amount: u64, ctx: &mut TxContext){
    // Burn debt tokens equal to repayment
    // TODO: add interest
    let debt_balance = coin::balance_mut(&mut debt_coin);
    let debt_coins = coin::take(debt_balance, amount, ctx);
    coin::burn(&mut pool.debt_cap, debt_coins);
    // Transfer payment
    let coin_balance = coin::balance_mut(&mut coin);
    let coins_to_repay = coin::take(coin_balance, amount, ctx);
    coin::join(&mut pool.balance, coins_to_repay);
    // Return collateral - ex: 50% LTV
    coin::mint_and_transfer<POOLCOIN>(&mut pool.lp_cap, 2*amount, tx_context::sender(ctx), ctx);
    // Return ownership
    coin::keep(coin, ctx);
    coin::keep(debt_coin, ctx);
  }

  /// === Reads ===

  // Check balance of pool
  public fun pool_balance(pool: &LendingPool): u64 {
    coin::value(&pool.balance)
  }

  #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
  }
}
