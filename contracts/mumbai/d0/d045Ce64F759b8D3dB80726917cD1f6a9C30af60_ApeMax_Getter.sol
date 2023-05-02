// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Libraries/Data_Structures.sol";
import "./Libraries/Fees_Functions.sol";

interface ApeMax_Public {
    function get_contract(uint64 contract_index) external view returns (Data_Structures.Contract memory);
    function get_stake(address stake_address) external view returns (Data_Structures.Stake memory);
    function get_global() external view returns (Data_Structures.Global memory);
}

// is Initializable
contract ApeMax_Getter {

    ApeMax_Public internal apemax_token;

    // function initialize(address apemax_contract_address) public initializer {
    constructor(address apemax_contract_address) {
        apemax_token = ApeMax_Public(apemax_contract_address);
    }

    function get_unclaimed_creator_rewards(
        uint64 contract_index
        )
        public view
        returns (uint128)
    {
        return apemax_token.get_contract(contract_index).unclaimed_creator_rewards;
    }

    function get_unclaimed_ministerial_rewards()
        public view
        returns (uint128)
    {
        return apemax_token.get_global().unclaimed_ministerial_rewards;
    }

    function get_staking_fees(
        uint128 amount_staked,
        uint64 contract_index
        )
        public view
        returns (Data_Structures.Split memory)
    {

        Data_Structures.Contract memory Contract = apemax_token.get_contract(contract_index);

        return Fees_Functions.calculate_inbound_fees(
            amount_staked,
            Contract.royalties,
            Contract.total_staked
        );
    }

    function get_staking_rewards(
        address stake_address,
        uint64 contract_index
        )
        public view
        returns (uint128)
    {
        // Create storage / pointer references to make code cleaners
        Data_Structures.Stake memory Stake = apemax_token.get_stake(stake_address);
        Data_Structures.Contract memory Contract = apemax_token.get_contract(contract_index);

        // Exit early if no claim so state is not affected
        uint32 time_elapsed = uint32(block.timestamp) - Stake.init_time;
        if (time_elapsed < Stake.delay_nerf) {
            return 0;
        }

        // Get finders fees owed
        uint160 relevant_multiple = Contract.total_multiple - Stake.multiple;
        uint256 finders_fees =
            relevant_multiple *
            Stake.amount_staked_raw *
            Constants.finders_fee / 10000
            / Constants.decimals;
        
        // Get relevant portions for computation
        uint160 relevant_units =
            Contract.reward_units -
            Stake.historic_reward_units;

        // Compute rewards
        uint256 rewards = 
            Stake.amount_staked *
            relevant_units /
            Constants.decimals;
        
         // Add in finders fees
        rewards += finders_fees;

        // Nerf rewards for delay only for the first claim
        if (Stake.has_been_delay_nerfed == false) {
            uint256 nerfed_rewards =
                rewards *
                (time_elapsed - Stake.delay_nerf) /
                time_elapsed;
            
            rewards = nerfed_rewards;
        }

        return uint128(rewards);
    }

    function get_staking_rewards_batch(
        address[] memory stake_addresses,
        uint64[] memory contract_indexes
        )
        public view
        returns (uint128[] memory)
    {
        require(
            stake_addresses.length == contract_indexes.length,
            "Invalid request"
        );

        uint128[] memory rewards_array = new uint128[](stake_addresses.length);

        for (uint256 i = 0; i < stake_addresses.length; i++) {
            uint128 rewards = get_staking_rewards(
                stake_addresses[i],
                contract_indexes[i]
            );
            rewards_array[i] = rewards;
        }

        return rewards_array;
    }

    function get_contract_ranking(
        uint32 results_per_age,
        uint64 page_number,
        bool high_to_low
        )
        public view
        returns (Data_Structures.Contract[] memory)
    {
        uint64 contract_count = apemax_token.get_global().contract_count;

        uint64 start_index = page_number * results_per_age;
        uint64 end_index = start_index + results_per_age;
        end_index = end_index > contract_count ? contract_count : end_index;

        Data_Structures.Contract[] memory sorted_contracts = new Data_Structures.Contract[](end_index - start_index);

        for (uint64 i = 0; i < contract_count; i++) {
            Data_Structures.Contract memory current_contract = apemax_token.get_contract(i);
            for (uint64 j = start_index; j < end_index; j++) {

                bool should_replace = high_to_low
                    ? current_contract.total_staked > sorted_contracts[j - start_index].total_staked
                    : current_contract.total_staked < sorted_contracts[j - start_index].total_staked;
                
                if (should_replace) {
                    for (uint64 k = end_index - 1; k > j; k--) {
                        sorted_contracts[k - start_index] = sorted_contracts[k - start_index - 1];
                    }
                    sorted_contracts[j - start_index] = current_contract;
                    break;
                }

            }
        }

        return sorted_contracts;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {

    // ------- Addresses -------

    // USDT address
    address internal constant usdt_address = 0x466DD1e48570FAA2E7f69B75139813e4F8EF75c2;
    //0xB6434EE024892CBD8e3364048a259Ef779542475; //0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    // USDC address
    address internal constant usdc_address = 0xd33602Ce228aDBc90625e4FC8071aAE0CAd11Fe9;
    // 0x6f14C02Fc1F78322cFd7d707aB90f18baD3B54f5; //0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Founder Wallets
    address internal constant founder_0 = 0xA43FA31dDD34EDdbBFe8af3dfF55650F79bC9Ea7;
    address internal constant founder_1 = 0xA43FA31dDD34EDdbBFe8af3dfF55650F79bC9Ea7;
    address internal constant founder_2 = 0xA43FA31dDD34EDdbBFe8af3dfF55650F79bC9Ea7;
    address internal constant founder_3 = 0xA43FA31dDD34EDdbBFe8af3dfF55650F79bC9Ea7;

    // Company
    address internal constant company_wallet = 0xA43FA31dDD34EDdbBFe8af3dfF55650F79bC9Ea7;

    // Price signing
    address internal constant pricing_authority = 0xc554e8d03e72252470FdEc29cf67b27f96CDfBc9;

    // ------- Values -------

    // Standard amount of decimals we usually use
    uint128 internal constant decimals = 10 ** 18; // Same as Ethereum

    // Token supply
    uint128 internal constant founder_reward = 50 * 10**9 * decimals; // 4x 50 Billion
    uint128 internal constant company_reward = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant max_presale_quantity = 200 * 10**9 * decimals; // 200 Billion
    uint128 internal constant maximum_subsidy = 400 * 10**9 * decimals; // 400 Billion

    // Fees and taxes these are in x100 for some precision
    uint128 internal constant ministerial_fee = 100;
    uint128 internal constant finders_fee = 100;
    uint128 internal constant minimum_tax_rate = 50;
    uint128 internal constant maximum_tax_rate = 500;
    uint128 internal constant tax_rate_range = maximum_tax_rate - minimum_tax_rate;
    uint16 internal constant maximum_royalties = 2500;
    
    // Values for subsidy
    uint128 internal constant subsidy_duration = 946080000; // 30 years
    uint128 internal constant max_subsidy_rate = 3 * maximum_subsidy / subsidy_duration;


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Data_Structures {

    struct Split {
        uint128 staker;
        uint128 tax;
        uint128 ministerial;
        uint128 creator;
        uint128 total;
    }

    struct Stake {

        // Used in calculating the finders fees owed to a user
        uint160 multiple;

        // The historic level of the reward units at the last claim...
        uint160 historic_reward_units;

        // Amount user has comitted to this stake
        uint128 amount_staked;

        // Amount user sent to stake, needed for fees calculation
        uint128 amount_staked_raw;

        // Address of the staker
        address staker_address;

        // The address of the contract corresponding to this stake
        uint64 contract_index;

        // The amount of time you need to wait for your first claim. Basically the waiting list time
        uint32 delay_nerf;

        // Stake init time
        uint32 init_time;

        // If the stake has been nerfed with regards to thr waitlist
        bool has_been_delay_nerfed;
        
    }


    struct Contract {

        // The total amount of units so we can know how much a token staked is worth
        // calculated as incoming rewards * 1-royalty / total staked
        uint160 reward_units;

        // Used in calculating staker finder fees
        uint160 total_multiple;

        // The total amount of staked comitted to this contract
        uint128 total_staked;

        // Rewards allocated for the creator of this stake, still unclaimed
        uint128 unclaimed_creator_rewards;

        // The contract address of this stake
        address contract_address;
        
        // The assigned address of the creator
        address owner_address;

        // The rate of the royalties configured by the creator
        uint16 royalties;
        
    }

    struct Global {

        // Used as a source of randomness
        uint256 random_seed;

        // The total amount staked globally
        uint128 total_staked;

        // The total amount of ApeMax minted
        uint128 total_minted;

        // Unclaimed amount of ministerial rewards
        uint128 unclaimed_ministerial_rewards;

        // Extra subsidy lost to mint nerf. In case we want to do something with it later
        uint128 nerfed_subsidy;

        // The number of contracts
        uint64 contract_count;

        // The time at which this is initialized
        uint32 init_time;

        // The last time we has to issue a tax, used for subsidy range calulcation
        uint32 last_subsidy_update_time;

        // The last time a token was minted
        uint32 last_minted_time;

    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Data_Structures.sol";
import "./Constants.sol";

library Fees_Functions {

    /*
        Returns percentage tax at current time
        Tax ranges from 1% to 5%
        In 100x denomination
    */
    function calculate_tax(
        uint128 total_staked
        )
        internal pure
        returns(uint128)
    {

        if (total_staked >= Constants.maximum_subsidy) {
            return Constants.maximum_tax_rate;
        }

        return
            Constants.minimum_tax_rate +
            Constants.tax_rate_range *
            total_staked /
            Constants.maximum_subsidy;

    }

    /*
        Calculates fees to be shared amongst all parties when a new stake comes in
    */
    function calculate_inbound_fees(
        uint128 amount_staked,
        uint16 royalties,
        uint128 total_staked
        )
        internal pure
        returns(Data_Structures.Split memory)
    {
        Data_Structures.Split memory inbound_fees;
        
        inbound_fees.staker = Constants.finders_fee * amount_staked / 10000;
        inbound_fees.ministerial = Constants.ministerial_fee * amount_staked / 10000;
        inbound_fees.tax = amount_staked * calculate_tax(total_staked) / 10000;
        inbound_fees.creator = amount_staked * royalties / 1000000;
        
        inbound_fees.total =
            inbound_fees.staker +
            inbound_fees.ministerial + 
            inbound_fees.tax +
            inbound_fees.creator;

        return inbound_fees;
    }

}