module lending_pool::pool {
  use sui::id::VersionedID;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::coin::{Self, Coin, TreasuryCap};
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

  struct POOLCOIN has drop {}

  // Deposit funds for a user (Only callable by pool owner)
  public entry fun deposit(pool: &mut LendingPool, depositor: address, amount: Coin<SUI>, treasury_cap: &mut TreasuryCap<POOLCOIN>, ctx: &mut TxContext) {
    let b = coin::into_balance(amount);
    let amount_to_mint = balance::value(&b);
    // Deposit SUI tokens
    balance::join(&mut pool.balance, b);
    // Give the depositor pool tokens in return
    let owed_coins = coin::mint<POOLCOIN>(treasury_cap, amount_to_mint, ctx);
    coin::transfer(owed_coins, depositor);
  }

  // Create a pool
  fun init(ctx: &mut TxContext) {
    transfer::share_object(LendingPool {
      id: tx_context::new_id(ctx),
      owner: tx_context::sender(ctx),
      balance: balance::zero<SUI>()
    });
    let treasury_cap = coin::create_currency<POOLCOIN>(POOLCOIN{}, ctx);
    transfer::transfer(treasury_cap, tx_context::sender(ctx));
  }

  #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
  }
}