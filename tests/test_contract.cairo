use core::array::Array;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use song_contract::interface::{ISongMarketplaceDispatcher, ISongMarketplaceDispatcherTrait};
use starknet::{ContractAddress, contract_address_const};

fn __setup__() -> (ContractAddress, ISongMarketplaceDispatcher) {
    let contract_name: ByteArray = "SongMarketplace";
    let contract = declare(contract_name)
        .expect('error declaring SongMarketplace')
        .contract_class();
    let mut calldata: Array<felt252> = array![];

    let owner_felt: felt252 = 0x12344.into();
    // let owner: ContractAddress = owner_felt.try_into().unwrap();

    calldata.append(owner_felt);
    let (contract_address, _) = contract
        .deploy(@calldata)
        .expect('error deploying SongMarketplace');
    let dispatcher = ISongMarketplaceDispatcher { contract_address };
    (contract_address, dispatcher)
}

#[test]
fn test_get_user_songs_empty() {
    let (_, dispatcher) = __setup__();

    let user_felt: felt252 = 0x12345.into();
    let user: ContractAddress = user_felt.try_into().unwrap();
    // Get songs for a user who hasn't registered any
    let songs = dispatcher.get_user_songs(user);

    // Check that the returned array is empty
    assert(songs.len() == 0, 'Should return empty array');
}

#[test]
fn test_get_user_songs_single() {
    let (contract_address, dispatcher) = __setup__();

    let user_felt: felt252 = 0x12345.into();
    let user: ContractAddress = user_felt.try_into().unwrap();
    // Set the caller to the test user
    start_cheat_caller_address(contract_address, user);

    // Register a song using the actual contract function
    let song_id = dispatcher
        .register_song('Test Song', 'ipfs_hash_1', 'preview_hash_1', 1000_u256, true);

    // Get songs for the user
    let songs = dispatcher.get_user_songs(user);

    // Check that the returned array contains the registered song
    assert(songs.len() == 1, 'Should have 1 song');
    assert(*songs.at(0) == song_id, 'Song ID mismatch');

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_get_user_songs_multiple() {
    let (contract_address, dispatcher) = __setup__();
    let user_felt: felt252 = 0x12345.into();
    let user: ContractAddress = user_felt.try_into().unwrap();
    // Set the caller to the test user
    start_cheat_caller_address(contract_address, user);

    // Register multiple songs
    let song_id1 = dispatcher
        .register_song('Test Song 1', 'ipfs_hash_1', 'preview_hash_1', 1000_u256, true);

    let song_id2 = dispatcher
        .register_song('Test Song 2', 'ipfs_hash_2', 'preview_hash_2', 2000_u256, false);

    let song_id3 = dispatcher
        .register_song('Test Song 3', 'ipfs_hash_3', 'preview_hash_3', 3000_u256, true);

    // Get songs for the user
    let songs = dispatcher.get_user_songs(user);

    // Check that the returned array contains all registered songs
    assert(songs.len() == 3, 'Should have 3 songs');
    assert(*songs.at(0) == song_id1, 'Song ID 1 mismatch');
    assert(*songs.at(1) == song_id2, 'Song ID 2 mismatch');
    assert(*songs.at(2) == song_id3, 'Song ID 3 mismatch');

    stop_cheat_caller_address(contract_address);
}


#[test]
fn test_is_song_owner_true() {
    let (contract_address, dispatcher) = __setup__();

    let user_felt: felt252 = 0x12345.into();
    let user: ContractAddress = user_felt.try_into().unwrap();

    start_cheat_caller_address(contract_address, user);

    let song_id = dispatcher
        .register_song('My Song', 'my_ipfs_hash', 'my_preview_hash', 1000_u256, false);

    // Check if the user is the owner of the song
    let is_owner = dispatcher.is_song_owner(user, song_id);

    assert(is_owner, 'User should be the owner');

    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expect: 'Non-owner should not be owner')]
fn test_is_song_owner_false() {
    let (contract_address, dispatcher) = __setup__();

    // user addresses
    let owner_felt: felt252 = 0x12345.into();
    let owner: ContractAddress = owner_felt.try_into().unwrap();

    let non_owner_felt: felt252 = 0x12346.into();
    let non_owner: ContractAddress = non_owner_felt.try_into().unwrap();

    // set the caller to the owner
    start_cheat_caller_address(contract_address, owner);

    // register a song as the owner
    let song_id = dispatcher
        .register_song('Owner Song', 'owner_ipfs_hash', 'owner_preview_hash', 1000_u256, false);

    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, non_owner);

    // check if the non-owner is the owner of the song
    let is_owner = dispatcher.is_song_owner(non_owner, song_id);

    // the non-owner should not be the owner
    assert(is_owner, 'Non-owner should not be owner');
    stop_cheat_caller_address(contract_address);
}


#[test]
fn test_is_song_owner_invalid_id() {
    let (_, dispatcher) = __setup__();

    // user address
    let user_felt: felt252 = 0x12345.into();
    let user: ContractAddress = user_felt.try_into().unwrap();

    // check if the user is the owner of a song with an invalid ID
    let is_owner = dispatcher.is_song_owner(user, 9999);

    // should return false for invalid song ID
    assert(!is_owner, 'Should be false for invalid ID');
}
