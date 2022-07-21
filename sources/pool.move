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
  struct DEBTCOIN has drop {}


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

  // Withdraw collateral
  public entry fun withdraw(pool: &mut LendingPool, collateral: Coin<POOLCOIN>, balance: Coin<SUI>, amount: u64, treasury_cap: &mut TreasuryCap<POOLCOIN>, ctx: &mut TxContext) {
    assert!(amount > 0, 0);
    // Reduce user's POOLCOIN balance
    let collateral_balance = coin::balance_mut(&mut collateral);
    let withdrawn_collateral = coin::take(collateral_balance, amount, ctx);
    // Burn POOLCOINs
    coin::burn(treasury_cap, withdrawn_collateral);
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
  public entry fun borrow(pool: &mut LendingPool, collateral: Coin<POOLCOIN>, balance: Coin<SUI>, amount: u64, pool_treasury: &mut TreasuryCap<POOLCOIN>, debt_treasury: &mut TreasuryCap<DEBTCOIN>, ctx: &mut TxContext){
    assert!(amount >0, 0);
    // LTV 50%
    let borrow_balance = coin::balance_mut(&mut collateral);
    let borrow_coins = coin::take(borrow_balance, 2*amount, ctx);
    // Burn POOLCOINs
    coin::burn(pool_treasury, borrow_coins);
    coin::keep(collateral, ctx);
    // Reduce pool's SUI balance
    let pool_bal = coin::balance_mut(&mut pool.balance);
    // Send withdrawn coins to user
    let withdrawal = coin::take(pool_bal, amount, ctx);
    let user_balance = coin::balance_mut(&mut balance);
    coin::put(user_balance, withdrawal);
    coin::keep(balance, ctx);
    // Mint debt tokens
    coin::mint_and_transfer<DEBTCOIN>(debt_treasury, amount, tx_context::sender(ctx), ctx);
  }

  public entry fun repay(pool: &mut LendingPool, coin: Coin<SUI>, debt_coin: Coin<DEBTCOIN>, amount: u64, pool_treasury: &mut TreasuryCap<POOLCOIN>, debt_treasury: &mut TreasuryCap<DEBTCOIN>, ctx: &mut TxContext){
    // Burn debt tokens equal to repayment
    // TODO: add interest
    let debt_balance = coin::balance_mut(&mut debt_coin);
    let debt_coins = coin::take(debt_balance, amount, ctx);
    coin::burn(debt_treasury, debt_coins);
    // Transfer payment
    let coin_balance = coin::balance_mut(&mut coin);
    let coins_to_repay = coin::take(coin_balance, amount, ctx);
    coin::join(&mut pool.balance, coins_to_repay);
    // Return collateral - 50% LTV
    coin::mint_and_transfer<POOLCOIN>(pool_treasury, 2*amount, tx_context::sender(ctx), ctx);
    // Return ownership
    coin::keep(coin, ctx);
    coin::keep(debt_coin, ctx);
  }

  // Create a pool
  fun init(ctx: &mut TxContext) {
    transfer::share_object(LendingPool {
      id: tx_context::new_id(ctx),
      owner: tx_context::sender(ctx),
      balance: coin::zero<SUI>(ctx)
    });
    let treasury_cap = coin::create_currency<POOLCOIN>(POOLCOIN{}, ctx);
    let debt_treasury = coin::create_currency<DEBTCOIN>(DEBTCOIN{}, ctx);
    transfer::share_object(treasury_cap);
    transfer::share_object(debt_treasury);
  }

  #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
  }
}
