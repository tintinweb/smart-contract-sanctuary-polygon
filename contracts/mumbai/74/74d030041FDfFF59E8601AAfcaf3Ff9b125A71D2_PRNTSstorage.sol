// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PRNTSstorage is Ownable {
    mapping(address => mapping(string => Publication))
        internal artistToPublications;

    mapping(address => Joiner) internal joiners;

    /**
    * @notice Defining a Publication for data retrieval
    * @param joiners - An array of joiners for the project
    * @param monthlyRevenues - Map monthYear to revenue array
    * @param distributableEarnings - Map monthYear to amount of distributable earnings
    * @param sfIndexId - Superfluid Index ID for revenue Distribution
    */
    struct Publication {
        address[] publicationJoiners;
        mapping(string => uint256[]) monthlyRevenues;
        mapping(string => uint256) totalMonthlyRevenue;
        mapping(string => uint256) distributableEarnings;
        uint256 sfIndexId;
    }

    /**
    * @notice Defining a joiner for data retrieval
    * @param joinedPublications - A list of publications the given address has joined
    * @param monthlyEarnings - An array of earnings from different sources
    * @param totalMonthlyEarnings - Total monthly earnings added up from monthlyEarnings
    */
    struct Joiner {
        string[] joinedPublications;
        mapping(string => mapping(string => uint256)) monthlyEarnings;
        mapping(string => uint256) totalMonthlyEarnings;
    }

    event PublicationEarningsUpdated(
        address indexed artistAddress,
        string indexed publicationId,
        string indexed monthYear,
        uint256[] revenueBySource,        
        uint256 totalRevenue
    );
    event PublicationEarningsRemoved(
        address indexed artistAddress,
        string indexed publicationId,
        string indexed monthYear
    );
    event PublicationDistributableBalanceUpdated(
        address indexed artistAddress,
        string indexed publicationId,
        string indexed monthYear,
        uint256 amount
    );
    event PublicationDistributableBalanceRemoved(
        address indexed artistAddress,
        string indexed publicationId,
        string indexed monthYear
    ); 
    event PublicationJoinerAdded(
        address indexed artistAddress,
        string indexed publicationId,
        address indexed joinerAddressAddress
    );
    event PublicationJoinerRemoved(        
        address indexed artistAddress,
        string indexed publicationId,
        address indexed joinerAddressAddress
    );    
    event PublicationJoinerBalanceUpdated(
        address indexed joinerAddress,
        string indexed publicationId,
        string indexed monthYear,
        uint256 amount
    );
    event PublicationJoinerBalanceRemoved(
        address indexed joinerAddress,
        string indexed publication_revenuesId
    );
    event SFIndexIDUpdated(
        address indexed artistAddress,
        string indexed publicationId,
        uint256 indexed sfIndex
    );

    /**
     * @notice Add to a publication's distributable earnings
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     * @param _monthYear - Month & Year of earnings
     * @param _revenues - array of revenues from various sources
     */
    function updatePublicationEarnings(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear,
        uint256[] calldata _revenues
    ) external onlyOwner {
       uint256 totalRevenue = artistToPublications[_artistAddress][_publicationId].totalMonthlyRevenue[_monthYear];
       
        /// @dev loop through given _revenues array and push into monthlyRevenues array
        /// @notice this is done this way so values can be added adhoc if need be
       for (uint256 i = 0; i < _revenues.length; i++) {
        uint256 revenue = _revenues[i];
        artistToPublications[_artistAddress][_publicationId].monthlyRevenues[_monthYear].push(revenue);
        artistToPublications[_artistAddress][_publicationId].totalMonthlyRevenue[_monthYear] += revenue;
       }
       
        emit PublicationEarningsUpdated(
            _artistAddress,
            _publicationId,
            _monthYear,
            _revenues,
            totalRevenue
        );
    }

    /**
     * @notice Reset a publication's earnings
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     * @param _monthYear - Month and year (MM/YYYY format) of earnings
     */
    function removePublicationEarnings(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear
    ) external onlyOwner {
        // Reset all earnings to 0
        uint256[] memory revenues = artistToPublications[_artistAddress][_publicationId].monthlyRevenues[_monthYear];

        for (uint256 i = 0; i < revenues.length; i++) {
            artistToPublications[_artistAddress][_publicationId].monthlyRevenues[_monthYear].pop();
        }

        emit PublicationEarningsRemoved(_artistAddress, _publicationId, _monthYear);
    }

    /**
     * @notice Update a publication's distributable earnings
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     * @param _monthYear - Month and year (MM/YYYY format) of earnings
     * @param _amount - Earnings
     */
    function updatePublicationDistributableEarnings(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear,
        uint256 _amount
    ) external onlyOwner {
        artistToPublications[_artistAddress][_publicationId].distributableEarnings[_monthYear] = _amount;

        emit PublicationDistributableBalanceUpdated(_artistAddress, _publicationId, _monthYear, _amount);
    } 

    /**
     * @notice Remove a publication's distributable earnings
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     * @param _monthYear - Month and year (MM/YYYY format) of earnings
     */
    function removePublicationDistributableEarnings(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear
    ) external onlyOwner {
        artistToPublications[_artistAddress][_publicationId].distributableEarnings[_monthYear] = 0;
        emit PublicationDistributableBalanceRemoved(_artistAddress, _publicationId, _monthYear);
    }
    

    /**
     ************ PUBLICATION JOINERS ************
     */

    /**
     * @notice Add a joiner to the publication
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     * @param _joinerAddress - address of the wallet joining the project
     */     
    function addPublicationJoiner(
        address _artistAddress,
        string calldata _publicationId,
        address _joinerAddress
    ) external onlyOwner {
        /// @dev - loop array to check for existing address
        for (
            uint256 i = 0;
            i <
            artistToPublications[_artistAddress][_publicationId].publicationJoiners.length;
            i++
        ) {
            if (
                keccak256(abi.encode(
                    artistToPublications[_artistAddress][_publicationId].publicationJoiners[
                    i
                ])) == keccak256(abi.encode(_joinerAddress))
            ) {
                /// @dev - tx MUST fail if _joinerAddress already exists in the array
                revert("address already joined publication");
            }
        }
        /// @dev - Add holder to publication's array of holders
        artistToPublications[_artistAddress][_publicationId].publicationJoiners.push(_joinerAddress);
        joiners[_joinerAddress].joinedPublications.push(_publicationId);
        
        emit PublicationJoinerAdded(_artistAddress, _publicationId, _joinerAddress);
    }

    /**
     * @notice Remove a Joiner from a given publication
     * @param _publicationId - publication ID string
     * @param _artistAddress - address of the artist
     * @param _joinerAddress - address of the joiner
     */
    function removePublicationJoiner(
        address _artistAddress,
        string calldata _publicationId,
        address _joinerAddress
    ) external onlyOwner {
        /// @dev -  Remove holder from publication's array of holders
        removeHolder(_artistAddress, _publicationId, _joinerAddress);
        emit PublicationJoinerRemoved(_artistAddress, _publicationId, _joinerAddress);
    }

    /**
     * @notice Look up joiner address and add to balance
     * @param _publicationId - publication ID string
     * @param _joinerAddress - address of the joiner
     * @param _amount - Amount to add to holder balance
     */
    function updateJoinerBalance(
        string calldata _publicationId,
        string calldata _monthYear,
        address _joinerAddress,
        uint256 _amount
    ) external onlyOwner {
        /// @dev - loop through array to find joiner index and add amount

        joiners[_joinerAddress].monthlyEarnings[_publicationId][_monthYear] = _amount;
        joiners[_joinerAddress].totalMonthlyEarnings[_monthYear] += _amount;

        emit PublicationJoinerBalanceUpdated(
            _joinerAddress,
            _publicationId,
            _monthYear,
            _amount
        );
    }

    /**
     * @notice Look up joiner address and remove balance
     * @param _publicationId - publication ID string
     * @param _joinerAddress - address of the joiner
     */

    function removeJoinerEarnings(
        string calldata _publicationId,
        string calldata _monthYear,
        address _joinerAddress
    ) external onlyOwner {
        /// @dev - loop through array to find joiner index and set holder's amount to 0

        joiners[_joinerAddress].monthlyEarnings[_publicationId][_monthYear] = 0;

        emit PublicationJoinerBalanceRemoved(_joinerAddress, _publicationId);
    }

    /**
     ************ SUPERFLUID STORAGE ************
     */

    /**
     * @notice Update Superfluid Index ID of publication
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     * @param _sfIndex - index IDAv1 Index ID
     */
    function updateSFIndex(
        address _artistAddress,
        string calldata _publicationId,
        uint256 _sfIndex
    ) public onlyOwner {
        artistToPublications[_artistAddress][_publicationId].sfIndexId = _sfIndex;
        emit SFIndexIDUpdated(_artistAddress, _publicationId, _sfIndex);
    }

    /**
     * @notice Update Superfluid Index ID of publication
     * @param _artistAddress - address of the artist
     * @param _publicationId - publication ID string
     */

    function removeSFIndex(
        address _artistAddress,
        string calldata _publicationId
    ) public onlyOwner {
        artistToPublications[_artistAddress][_publicationId].sfIndexId = 0;
        emit SFIndexIDUpdated(_artistAddress, _publicationId, 0);
    }

    /**
     ************ GETTERS ************
     */

    function getPublicationDistributableBalance(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear
    ) public view returns (uint256) {
        uint256 distributableBalance = artistToPublications[
            _artistAddress
        ][_publicationId].distributableEarnings[_monthYear];
        return distributableBalance;
    }

    function getPublicationRevenues(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear
    ) public view returns (uint256[] memory) {
        uint256[] memory revenues = artistToPublications[_artistAddress][_publicationId].monthlyRevenues[_monthYear];
        return revenues;
    }

    function getPublicationMonthlyRevenue(
        address _artistAddress,
        string calldata _publicationId,
        string calldata _monthYear
    ) public view returns (uint256) {
        uint256 monthlyBalance = artistToPublications[
            _artistAddress
        ][_publicationId].totalMonthlyRevenue[_monthYear];
        return monthlyBalance;
    }

    function getPublicationJoiners(
        address _artistAddress,
        string calldata _publicationId
    ) public view returns (address[] memory) {
        address[] storage joinerAddresses;
        joinerAddresses = artistToPublications[_artistAddress][_publicationId].publicationJoiners;
        return joinerAddresses;
    }

    function getJoinerTotalMonthlyBalance(
        string calldata _monthYear,
        address _joinerAddress
    ) public view returns (uint256) {

        uint256 balance = joiners[_joinerAddress].totalMonthlyEarnings[_monthYear];
        return balance;
    }

    function getJoinerMonthlyPublicationBalance(
        address _joinerAddress,
        string calldata _publicationId,
        string calldata _monthYear
    ) public view returns (uint256) {

        uint256 balance = joiners[_joinerAddress].monthlyEarnings[_publicationId][_monthYear];
        return balance;
    }

    function getSFIndex(address _artistAddress, string calldata _publicationId)
        public
        view
        returns (uint256)
    {
        uint256 index = artistToPublications[_artistAddress][_publicationId].sfIndexId;
        return index;
    }

    /**
     ************ INTERNAL HELPERS ************
     */

    function removeHolder(
        address _artistAddress,
        string calldata _publicationId,
        address _joinerAddress
    ) internal {
        // Loop through publication holders array and remove holder
        for (
            uint256 i = 0;
            i <
            artistToPublications[_artistAddress][_publicationId].publicationJoiners.length;
            i++
        ) {
            if (
                keccak256(abi.encode(artistToPublications[_artistAddress][_publicationId].publicationJoiners[i])) ==
                keccak256(abi.encode(_joinerAddress))
            ) {
                //This is the holder to remove;
                remove(_artistAddress, _publicationId, i);
            } else {
                revert("Address has not joined the publication");
            }
        }
    }

    function removePublicationFromJoiner(
        address _joinerAddress,
        string calldata _publicationId
    ) internal {

        for (uint256 i = 0; i < joiners[_joinerAddress].joinedPublications.length; i++) {
            if (keccak256(abi.encode(_publicationId)) 
                == 
                keccak256(abi.encode(joiners[_joinerAddress].joinedPublications[i])))
                {
                    removePublication(_joinerAddress, i);
                }
        }
    }

    function remove(
        address _artistAddress,
        string calldata _publicationId,
        uint256 index
    ) internal {
        // If the index is out of range of the array, return
        if (
            index >=
            artistToPublications[_artistAddress][_publicationId].publicationJoiners.length
        ) return;

        // Loop through array and move given index to the end of the array
        for (
            uint256 i = index;
            i <
            artistToPublications[_artistAddress][_publicationId].publicationJoiners.length -
                1;
            i++
        ) {
            artistToPublications[_artistAddress][_publicationId].publicationJoiners[i] = artistToPublications[_artistAddress][_publicationId].publicationJoiners[i + 1];
        }

        // Pop end of the array
        artistToPublications[_artistAddress][_publicationId].publicationJoiners.pop();
    }

    function removePublication(
        address _joinerAddress,
        uint256 _index
    ) internal {
        // If the index is out of range of the array, return
        if (_index >= joiners[_joinerAddress].joinedPublications.length) {
            return;
        }

        // Loop through array and move given index to the end of the array
        for (uint256 i = _index; i < joiners[_joinerAddress].joinedPublications.length - 1; i++) {
            joiners[_joinerAddress].joinedPublications[i] = joiners[_joinerAddress].joinedPublications[i + 1];
        }

        // Pop end of the array
        joiners[_joinerAddress].joinedPublications.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}