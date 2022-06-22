// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Finde {
    using Counters for Counters.Counter;
    Counters.Counter public _uriIndexCounter;

    // EVENTS
    event UriAdded(
        string uri,
        address provider,
        string[] tags
    );
    event UpVoted(
        address voter,
        address provider,
        uint256 time,
        uint256 upVotes,
        uint256 downVotes,
        string country
    );
    event DownVoted(
        address voter,
        address provider,
        uint256 time,
        uint256 upVotes,
        uint256 downVotes,
        string country
    );

    // STRUCTS
    struct Provider {
        string[] uris;
        Vote votes;
        address addr;
        string country;
        uint256 countryLocalIndex; // index in the country array
    }

    struct Vote {
        uint256 upVote;
        uint256 downVote;
    }

    // TOKEN
    IERC20 private _token;

    // STATE VARIABLES
    mapping(string => uint256[]) public countryToIndexs; // country to [indexs]
    mapping(address => uint256) public addressToIndex; // address to index( that points to the provider)

    mapping(uint256 => Provider) public indexToProvider; // index to provider
    mapping(address => mapping(address => Vote)) public providerVoters; // provider => voter => vote
    mapping(address => uint256) public voterTimeRecord; // to keep record of the time of the last vote
    mapping(string => string[]) public uriToTags; // uri => [tags]
    mapping(string => string[]) public tagToUris; // tag => [uris]
    mapping(string => mapping(string => string[])) public tagToCountryToUris; // tag => country => [uris]
    mapping(string => uint256) public uriToIndex; // uri => index
    mapping(string => string[]) public countryToUris; // country => [uris]
    mapping(address => mapping(string => string[])) public providerToTagToUris; // provider => tag => [uris]

    uint256 public votingWaitTime;
    uint256 public requiredTokensForVote;

    // MODIFIERS
    modifier EligibleToVote(address _providerAddress) {
        // validate if voter has enough tokens
        require(
            _token.balanceOf(msg.sender) >= requiredTokensForVote,
            "FINDE: Insufficient token balance"
        );
        // validate if the provider is already in the list
        require(
            addressToIndex[_providerAddress] != 0,
            "FINDE: Invalid provider address"
        );
        // _providerAddress and msg.sender should not be the same
        require(
            _providerAddress != msg.sender,
            "FINDE: Cannot vote for yourself"
        );
        // validate if voter has already voted
        require(
            providerVoters[_providerAddress][msg.sender].upVote < 1 &&
                providerVoters[_providerAddress][msg.sender].downVote < 1,
            "FINDE:  Already voted"
        );
        // check it's been more than `votingWaitTime` since the last vote
        require(
            voterTimeRecord[msg.sender] + votingWaitTime < block.timestamp,
            "FINDE: Can't vote more than once within {votingWaitTime}"
        );

        _;
    }

    // CONSTRUCTOR
    constructor(address _tokenAddress) {
        _token = IERC20(_tokenAddress);
        _uriIndexCounter.increment(); // start counter from 1;

        // ? Should we make these configurable using constructor params or setters?
        votingWaitTime = 1 minutes;
        requiredTokensForVote = 100;
    }

    // FUNCTIONS

    /**
     * @dev Add a new URI to the list of URIs.
     * @dev Emits an event when the URI is added with the URI, provider address and tags.
     * @param _uri URI to be added.
     * @param _tags Tags associated with the URI.
     * @param _country Country associated with the URI.
     */
    function addURI(
        string memory _uri,
        string memory _country,
        string[] memory _tags
    ) public {
        // validate if the uri is not empty
        require(
            compareStringsbyBytes(_uri, "") == false,
            "FINDE: URI is empty string"
        );
        // validate if country is not empty
        require(
            compareStringsbyBytes(_country, "") == false,
            "FINDE: Country is empty string"
        );

        if (addressToIndex[msg.sender] == 0) {
            string[] memory uris = new string[](1);
            uris[0] = _uri;
            indexToProvider[_uriIndexCounter.current()] = Provider({
                uris: uris,
                votes: Vote({upVote: 0, downVote: 0}),
                addr: msg.sender,
                country: _country,
                countryLocalIndex: countryToIndexs[_country].length
            });
            addressToIndex[msg.sender] = _uriIndexCounter.current();
            // add to country index
            countryToIndexs[_country].push(_uriIndexCounter.current());
            // add to country uris
            countryToUris[_country].push(_uri);
            // add to uri index
            uriToIndex[_uri] = _uriIndexCounter.current();

            _uriIndexCounter.increment();
        } else {
            indexToProvider[addressToIndex[msg.sender]].uris.push(_uri);
            // add to uri index
            uriToIndex[_uri] = addressToIndex[msg.sender];
            // add to country uris
            countryToUris[indexToProvider[addressToIndex[msg.sender]].country].push(_uri);
            
        }

        // add to provider to tag to uris
        for (uint i = 0; i < _tags.length; i++) {
            providerToTagToUris[msg.sender][_tags[i]].push(_uri);
        }

        // add tags
        if (_tags.length > 0) {
            for (uint256 i = 0; i < _tags.length; i++) {
                tagToUris[_tags[i]].push(_uri);
                uriToTags[_uri].push(_tags[i]);
                tagToCountryToUris[_tags[i]][
                    indexToProvider[addressToIndex[msg.sender]].country
                ].push(_uri);
            }
        }

        emit UriAdded(_uri, msg.sender, _tags);
    }

    /**
     * @dev Get a paginated list of URIs.
     * TODO: Sort by upVote and downVote is yet to be implemented.
     * ? Sould we allow the use to pass multiple tags?
     * ! Currently only one tag is supported.
     * ! Dont pass invalid _offset and _limit, you can validate this use methods like `getTagCountryUrisLength`, `getTagUrisLength` and `getCountryUrisLength`.
     * @param _offset Offset of the list.
     * @param _limit Limit of the list.
     * @param _country Country to filter the list.
     * @param _tag Tag to filter the list.
     * @return A list of URIs.
     */
    function getPaginatedURIs(
        uint256 _offset,
        uint256 _limit,
        string calldata _country,
        string calldata _tag
    ) external view returns (Provider[] memory) {
        require(_limit > 0 && _limit <= 100, "FINDE: Invalid limit.");
        require(_offset < _uriIndexCounter.current(), "FINDE: Invalid offset.");
        require(
            _offset + _limit <= _uriIndexCounter.current(),
            "FINDE: Invalid offset and limit."
        );

        Provider[] memory data = new Provider[](_limit);

        uint256 dataLength = 0;

        // possible cases:
        if (
            compareStringsbyBytes(_country, "") == true &&
            compareStringsbyBytes(_tag, "") == true
        ) {
            // if `_country` & `_tag` are empty,
            _offset = _offset + 1; // increase offset by 1 as _uriIndexCounter starts from 1

            // no country filter
            for (uint256 i = _offset; i < _offset + _limit; i++) {
                data[dataLength] = indexToProvider[i];
                dataLength++;
            }
            // return all providers based on the offset, limit
        } else if (
            compareStringsbyBytes(_country, "") == true &&
            compareStringsbyBytes(_tag, "") == false
        ) {
            // if `_country` is empty and `_tag` is not empty,
            if (
                tagToUris[_tag].length > 0 && tagToUris[_tag].length <= _limit
            ) {
                for (uint256 i = 0; i < tagToUris[_tag].length; i++) {
                    string[] memory temp_uris = new string[](1);
                    temp_uris[0] = tagToUris[_tag][i];
                    data[dataLength] = Provider({
                        uris: temp_uris,
                        votes: indexToProvider[uriToIndex[tagToUris[_tag][i]]]
                            .votes,
                        addr: indexToProvider[uriToIndex[tagToUris[_tag][i]]]
                            .addr,
                        country: indexToProvider[uriToIndex[tagToUris[_tag][i]]]
                            .country,
                        countryLocalIndex: indexToProvider[
                            uriToIndex[tagToUris[_tag][i]]
                        ].countryLocalIndex
                    });
                    dataLength++;
                }
            } else if (
                tagToUris[_tag].length > 0 && tagToUris[_tag].length > _limit
            ) {
                require(
                    _offset + _limit <= tagToUris[_tag].length,
                    "FINDE: Invalid offset and limit."
                );

                for (uint256 i = _offset; i < _offset + _limit; i++) {
                    string[] memory temp_uris = new string[](1);
                    temp_uris[0] = tagToUris[_tag][i];
                    data[dataLength] = Provider({
                        uris: temp_uris,
                        votes: indexToProvider[uriToIndex[tagToUris[_tag][i]]]
                            .votes,
                        addr: indexToProvider[uriToIndex[tagToUris[_tag][i]]]
                            .addr,
                        country: indexToProvider[uriToIndex[tagToUris[_tag][i]]]
                            .country,
                        countryLocalIndex: indexToProvider[
                            uriToIndex[tagToUris[_tag][i]]
                        ].countryLocalIndex
                    });
                    // data[dataLength] = indexToProvider[uriToIndex[tagToUris[_tag][i]]];
                    dataLength++;
                }
            } else {
                dataLength = 0;
                data = new Provider[](0);
            }

            // return all providers based on the offset, limit AND tags
        } else if (
            compareStringsbyBytes(_country, "") == false &&
            compareStringsbyBytes(_tag, "") == true
        ) {
            // if `_country` is not empty and `_tag` is empty,
            require(
                countryToIndexs[_country].length > 0,
                "FINDE: Invalid country."
            );
            require(
                _offset + _limit <= countryToIndexs[_country].length,
                "FINDE: Invalid offset and limit."
            );

            for (
                uint256 i = _offset;
                i < countryToIndexs[_country].length;
                i++
            ) {
                data[dataLength] = indexToProvider[
                    countryToIndexs[_country][i]
                ];
                dataLength++;
            }
            // return all providers based on the offset, limit AND country
        } else if (
            compareStringsbyBytes(_country, "") == false &&
            compareStringsbyBytes(_tag, "") == false
        ) {
            // if `_country` and `_tag` both are not empty,
            require(
                countryToIndexs[_country].length > 0,
                "FINDE: Invalid country."
            );
            require(
                tagToCountryToUris[_tag][_country].length <= _offset + _limit,
                "FINDE: Invalid offset and limit."
            );

            if (tagToCountryToUris[_tag][_country].length > 0) {
                for (
                    uint256 i = _offset;
                    i < tagToCountryToUris[_tag][_country].length;
                    i++
                ) {
                    string[] memory temp_uris = new string[](1);
                    temp_uris[0] = tagToCountryToUris[_tag][_country][i];
                    data[dataLength] = Provider({
                        uris: temp_uris,
                        votes: indexToProvider[
                            uriToIndex[tagToCountryToUris[_tag][_country][i]]
                        ].votes,
                        addr: indexToProvider[
                            uriToIndex[tagToCountryToUris[_tag][_country][i]]
                        ].addr,
                        country: indexToProvider[
                            uriToIndex[tagToCountryToUris[_tag][_country][i]]
                        ].country,
                        countryLocalIndex: indexToProvider[
                            uriToIndex[tagToCountryToUris[_tag][_country][i]]
                        ].countryLocalIndex
                    });
                    dataLength++;
                }
            } else {
                dataLength = 0;
                data = new Provider[](0);
            }
            // return all providers based on the offset, limit, country AND tags
        }

        return data;
    }

    /**
     * @dev Get a list of URIs of a provider.
     * @param _addr Address of the provider.
     * @param _offset Offset of the list.
     * @param _limit Limit of the list.
     * @return A list of URIs.
     */
    function getProviderURIs(
        uint256 _offset,
        uint256 _limit,
        address _addr,
        string memory _tag
    ) external view returns (string[] memory) {
        require(addressToIndex[_addr] != 0, "FINDE: Invalid address.");
        require(_limit > 0 && _limit <= 100, "FINDE: Invalid limit.");
        require(
            indexToProvider[addressToIndex[_addr]].uris.length > 0,
            "FINDE: No URIs."
        );
        string[] memory data = new string[](_limit);

        if (compareStringsbyBytes(_tag, "") == true) {
            require(
                _offset + _limit <=
                    indexToProvider[addressToIndex[_addr]].uris.length,
                "FINDE: Invalid offset."
            );
            for (uint256 i = _offset; i < _offset + _limit; i++) {
                data[i - _offset] = indexToProvider[addressToIndex[_addr]].uris[i];
            }
        } else {
            data = providerToTagToUris[_addr][_tag];
        }
       

        return data;
    }

    /**
     * @dev Upvote a provider.
     * @dev Emit an UpVoted event with the provider's address, URI, block.timestamp, upvote count, downvote count and country.
     * @param _providerAddress Address of the provider.
     */
    function upVoteProvider(address _providerAddress)
        external
        EligibleToVote(_providerAddress)
    {
        indexToProvider[addressToIndex[_providerAddress]].votes.upVote += 1;
        voterTimeRecord[msg.sender] = block.timestamp;
        providerVoters[_providerAddress][msg.sender].upVote += 1;

        emit UpVoted(
            msg.sender,
            _providerAddress,
            block.timestamp,
            indexToProvider[addressToIndex[_providerAddress]].votes.upVote,
            indexToProvider[addressToIndex[_providerAddress]].votes.downVote,
            indexToProvider[addressToIndex[_providerAddress]].country
        );
    }

    /**
     * @dev Downvote a provider.
     * @dev Emit a DownVoted event with the provider's address, URI, block.timestamp, upvote count, downvote count and country.
     * @param _providerAddress Address of the provider.
     */
    function downVoteProvider(address _providerAddress)
        external
        EligibleToVote(_providerAddress)
    {
        indexToProvider[addressToIndex[_providerAddress]].votes.downVote += 1;
        voterTimeRecord[msg.sender] = block.timestamp;
        providerVoters[_providerAddress][msg.sender].downVote += 1;

        emit DownVoted(
            msg.sender,
            _providerAddress,
            block.timestamp,
            indexToProvider[addressToIndex[_providerAddress]].votes.upVote,
            indexToProvider[addressToIndex[_providerAddress]].votes.downVote,
            indexToProvider[addressToIndex[_providerAddress]].country
        );
    }

    /**
     * @dev Get the votes of a provider.
     * @param _providerAddress Address of the provider.
     * @return The votes of the provider as a Vote struct.
     */
    function getProviderVotes(address _providerAddress)
        external
        view
        returns (Vote memory)
    {
        return indexToProvider[addressToIndex[_providerAddress]].votes;
    }

    /**
     * @dev Read the FindeToken balance of a wallet.
     * @param _account Wallet address.
     * @return The FindeToken balance of the wallet.
     */
    function readTokenBalance(address _account)
        external
        view
        returns (uint256)
    {
        return _token.balanceOf(_account);
    }

    /**
     * @dev Get the remaining time for a voter to vote.
     * @param _voter Address of the voter.
     * @return The remaining time for a voter to vote.
     */
    function getRemainingTimeForVote(address _voter)
        external
        view
        returns (int256)
    {
        int256 timeLeft = int256(
            (voterTimeRecord[_voter] + votingWaitTime) - block.timestamp
        );
        if (timeLeft >= 0) {
            return timeLeft;
        }
        return 0;
    }

    function compareStringsbyBytes(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    /**
     * @dev Get the number of URIs of a country.
     * @param _country Country name.
     * @return The number of URIs of a country.
     */
    function getCountryUrisLength(string memory _country)
        external
        view
        returns (uint256)
    {
        return countryToUris[_country].length;
    }

    /**
     * @dev Function to get the length of uris with a specific tag.
     * @param _tag The tag to get the length of uris.
     * @return The length of uris with the specific tag.
     */
    function getTagUrisLength(string memory _tag)
        external
        view
        returns (uint256)
    {
        return tagToUris[_tag].length;
    }

    /**
     * @dev Function to get the length of uris with a specific tag and country.
     * @param _tag The tag to get the length of uris.
     * @param _country The country to get the length of uris.
     * @return The length of uris with the specific tag and country.
     */
    function getTagCountryUrisLength(string memory _tag, string memory _country)
        external
        view
        returns (uint256)
    {
        return tagToCountryToUris[_tag][_country].length;
    }
    
    /**
     * @dev Function to get the length of uris of a provider.
     * @param _providerAddress The address of the provider.
     * @return The length of uris of the provider.
     */
    function getProviderUrisLength(address _providerAddress, string memory _tag)
        external
        view
        returns (uint256)
    {
        if(compareStringsbyBytes(_tag, "") == true) {
            return addressToIndex[_providerAddress] != 0
                ? indexToProvider[addressToIndex[_providerAddress]].uris.length
                : 0;
        }
        // provider to tag to uris
        return providerToTagToUris[_providerAddress][_tag].length;
        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}