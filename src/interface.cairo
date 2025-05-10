use starknet::ContractAddress;
use super::song_marketplace::Song;

#[starknet::interface]
pub trait ISongMarketplace<TContractState> {
    fn register_song(
        ref self: TContractState,
        song_name: felt252,
        song_ipfs_hash: felt252,
        preview_ipfs_hash: felt252,
        price: u256,
        for_sale: bool,
    ) -> u64;
    fn get_song_info(self: @TContractState, song_id: u64) -> Song;
    fn update_song_price(ref self: TContractState, song_id: u64, new_price: u256);
    fn get_preview(self: @TContractState, song_id: u64) -> felt252;
    fn buy_song(ref self: TContractState, song_id: u64) -> felt252;
    fn get_user_songs(self: @TContractState, user: ContractAddress) -> Array<u64>;
    fn is_song_owner(self: @TContractState, user: ContractAddress, song_id: u64) -> bool;
}
