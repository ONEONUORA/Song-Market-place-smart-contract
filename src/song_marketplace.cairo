use starknet::ContractAddress;
use super::interface::ISongMarketplace;

#[derive(Clone, Debug, Drop, PartialEq, Serde, starknet::Store)]
pub struct Song {
    name: felt252,
    ipfs_hash: felt252,
    preview_ipfs_hash: felt252,
    price: u256,
    owner: ContractAddress,
    for_sale: bool,
}

#[starknet::contract]
mod SongMarketplace {
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use super::{ISongMarketplace, Song};


    #[storage]
    struct Storage {
        songs: Map<u64, Song>,
        song_count: u64,
        user_songs: Map<(ContractAddress, u64), bool>,
        user_song_count: Map<ContractAddress, u64>,
        user_song_ids: Map<(ContractAddress, u64), u64>,
    }
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.song_count.write(0);
    }

    #[abi(embed_v0)]
    impl SongMarketplaceImpl of ISongMarketplace<ContractState> {
        fn register_song(
            ref self: ContractState,
            song_name: felt252,
            song_ipfs_hash: felt252,
            preview_ipfs_hash: felt252,
            price: u256,
            for_sale: bool,
        ) -> u64 {
            let caller = get_caller_address();

            assert!(song_name != 0, "Song name cannot be empty");
            assert!(song_ipfs_hash != 0, "Your song hash cannot be empty");
            assert!(preview_ipfs_hash != 0, "Your song preview hash cannot be empty");

            // Increment song count and return the new song ID
            let song_id = self.song_count.read();
            self.song_count.write(song_id + 1);

            let song = Song {
                name: song_name,
                ipfs_hash: song_ipfs_hash,
                preview_ipfs_hash: preview_ipfs_hash,
                price: price,
                owner: caller,
                for_sale: for_sale,
            };
            //store the song in the contract storage
            self.songs.write(song_id, song);

            // Update user song mappings
            let user_song_count = self.user_song_count.read(caller);
            self.user_songs.write((caller, song_id), true);
            self.user_song_ids.write((caller, user_song_count), song_id);
            self.user_song_count.write(caller, user_song_count + 1);
            song_id
        }

        // TODO: Implement function to get detailed song info
        fn get_song_info(self: @ContractState, song_id: u64) -> Song {
            // Check if the song_id is valid
            let total_songs = self.song_count.read();
            assert!(song_id < total_songs, "Song ID does not exist");

            // Read and return the song information from storage
            self.songs.read(song_id)
        }

        // TODO: Implement function to update the price of a song
        fn update_song_price(ref self: ContractState, song_id: u64, new_price: u256) {
            // Check if the song_id is valid
            let total_songs = self.song_count.read();
            assert!(song_id < total_songs, "Song ID does not exist");
            let mut song = self.songs.read(song_id);

            //Verify that the caller is the owner of the song
            let caller = get_caller_address();
            assert!(song.owner == caller, "Only the owner can update the song price");

            // Create new song instance with updated price
            song.price = new_price;

            // Write the updated song back to storage
            self.songs.write(song_id, song);
        }
        // TODO: Implement function to get the preview hash of a song
    // fn get_preview(...) -> felt252 { ... }

        // TODO: Implement function to buy a song and transfer ownership
    // fn buy_song(...) -> felt252 { ... }

        // TODO: Implement function to fetch songs owned by a specific user
    // fn get_user_songs(...) -> Array<u64> { ... }

        // TODO: Implement function to check if a user is the owner of a song
    // fn is_song_owner(...) -> bool { ... }
    }
}
