// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PRNTSstorage is Ownable {
    /**
     ********************************************
     *           DATA STRUCTURES                *
     ********************************************
     */

    /**
     * @notice Defining an Artist for data retrieval
     * @param id - Position within artists[] array for data retrieval;
     * @param profileId - Artist's Lens profile ID
     * @param artistAddress - Artists' wallet address
     */
    struct Artist {
        uint256 id;
        string profileId;
        address artistAddress;
    }

    /**
     * @notice Defining a Publication for data retrieval
     * @param id - Position within publictions[] array for data retrieval
     * @param publicationId - Publication's Lens Publication ID
     * @param artistId - Publication Artist's Lens Profile ID
     * @param sfIndexId - Superfluid Index ID for revenue distribution
     * @param pctProfitToDistribute - Percentage of total profit to share with fans
     * @param pctToDistributePerShare - Percentage of profit per share
     */
    struct Publication {
        uint256 id;
        string publicationId;
        string artistId;
        string sfIndexId;
        uint256 pctProfitToDistribute;
        uint256 pctToDistributePerShare;
    }

    /**
     * @notice Defining a fan for data retrieval
     * @param id - Position within publictions[] array for data retrieval
     * @param fanId - Fan's Lens profile ID
     * @param projectId - Publication's Lens publication ID
     * @param monthYear - Month and year of earnings
     * @param earningsAmount - Amount Fan has earned for this period
     * @param currency - ERC20 token used
     * @param fanAddress - Wallet address of fan
     */
    struct Fan {
        uint256 id;
        string fanId;
        string publicationId;
        string monthYear;
        uint256 earningsAmount;
        string currency;
        address fanAddress;
    }

    /**
     * @notice Defining revenues for data retrieval
     * @param projectId - Publication's Lens publication ID
     * @param monthYear - Month and year of revenues
     * @param earnings - JSON string of earnings by platform
     */
    struct Revenue {
        uint256 id;
        string projectId;
        string monthYear;
        string earnings;
    }

    /**
     ********************************************
     *               STORAGE ARRAYS             *
     ********************************************
     */

    Artist[] artists;
    Publication[] publications;
    Fan[] fans;
    Revenue[] revenues;

    /**
     ********************************************
     *                  EVENTS                  *
     ********************************************
     */
    event ArtistCreated(
        uint256 indexed _id,
        string indexed _artistId,
        address indexed _artistAddress
    );

    event PublicationCreated(
        uint256 indexed _id,
        string indexed _publicationId,
        string indexed _artistId,
        string _sfIndexId,
        uint256 _pctProfitToDistribute,
        uint256 _pctToDistributePerShare
    );

    event RevenueCreated(
        uint256 indexed _id,
        string indexed _publicationId,
        string indexed monthYear,
        string earnings
    );

    event RevenuesUpdated(
        string indexed _publicationId,
        string indexed _monthYear,
        string indexed _earnings
    );

    event ArtistAddressUpdated(
        string indexed _artistId,
        address indexed _artistAddress
    );

    event PublicationSFIndexIDUpdated(
        string indexed _publicationId,
        string indexed _artistId,
        string indexed _sfIndexId
    );

    event PublicationProfitDistributionUpdated(
        string indexed _publicationId,
        string indexed _artistId,
        uint256 _pctProfitDist
    );

    event PublicationDistributionPerShareUpdated(
        string indexed _publicationId,
        string indexed _artistId,
        uint256 _pctDistPerShare
    );

    event FanBalanceUpdated(
        string indexed _fanId,
        string indexed _publicationId,
        string indexed _monthYear,
        uint256 _earningsAmount,
        string _currency
    );

    event FanCreated(
        uint256 indexed _id,
        string indexed _fanId,
        string indexed _monthYear,
        uint256 _earningsAmount,
        string _currency
    );

    /**
     ********************************************
     *             STORAGE FUNCTIONS            *
     ********************************************
     */

    //               ====== CREATE NEW ======

    /**
     * @notice - Creates a new Artist struct and pushes into artists[] array
     * @param _artistId - Lens profile ID of artist
     * @param _artistAddress - Wallet address of Artist
     */
    function createArtist(string calldata _artistId, address _artistAddress)
        external
        onlyOwner
    {
        uint256 id = (artists.length + 1);

        ///@dev - Define new Artist
        Artist memory artist = Artist({
            id: id,
            profileId: _artistId,
            artistAddress: _artistAddress
        });

        ///@dev - push new Artist to artists[] array
        artists.push(artist);

        ///@dev - Emit even for creating an artist entry
        emit ArtistCreated(id, _artistId, _artistAddress);
    }

    /**
     * @notice - Creates a new Publication struct and pushes into publications[] array
     * @param _publicationId - Lens Publication ID of publication
     * @param _artistId - Lens Profile ID of artist
     * @param _sfIndexId - Superfluid Index ID of publication
     * @param _pctProfitToDistribute - Percentage of total profits to redistribute to fans
     * @param _pctToDistributePerShare - Percentage of total profits each fan gets
     */
    function createPublication(
        string calldata _publicationId,
        string calldata _artistId,
        string calldata _sfIndexId,
        uint256 _pctProfitToDistribute,
        uint256 _pctToDistributePerShare
    ) external onlyOwner {
        uint256 id = publications.length + 1;

        ///@dev - Define new Publication
        Publication memory publication = Publication({
            id: id,
            publicationId: _publicationId,
            artistId: _artistId,
            sfIndexId: _sfIndexId,
            pctProfitToDistribute: _pctProfitToDistribute,
            pctToDistributePerShare: _pctToDistributePerShare
        });

        ///@dev - push new Publication to publications[] array
        publications.push(publication);

        ///@dev - Emit event for creating a Publication
        emit PublicationCreated(
            id,
            _publicationId,
            _artistId,
            _sfIndexId,
            _pctProfitToDistribute,
            _pctToDistributePerShare
        );
    }

    /**
     * @notice - Creates a new Revenue struct and pushes into revenues[] array
     * @param _publicationId - Lens Publication ID of publication
     * @param _monthYear - Month and Year of earnings
     * @param _earnings - JSON string of earnings by source platform
     */
    function createRevenue(
        string calldata _publicationId,
        string calldata _monthYear,
        string calldata _earnings
    ) external onlyOwner {
        uint256 id = revenues.length + 1;

        ///@dev - Define a new Revenue
        Revenue memory revenue = Revenue({
            id: id,
            projectId: _publicationId,
            monthYear: _monthYear,
            earnings: _earnings
        });

        ///@dev - push new Revenue to revenues[] array
        revenues.push(revenue);

        ///@dev - Emit event for creating Revenue
        emit RevenueCreated(id, _publicationId, _monthYear, _earnings);
    }

    function createFan(
        string calldata _fanId,
        string calldata _publicationId,
        string calldata _monthYear,
        uint256 _earningsAmount,
        string calldata _currency,
        address _fanAddress
    ) external onlyOwner {
        uint256 id = fans.length + 1;

        ///@dev - Define new Fan
        Fan memory fan = Fan({
            id: id,
            fanId: _fanId,
            publicationId: _publicationId,
            monthYear: _monthYear,
            earningsAmount: _earningsAmount,
            currency: _currency,
            fanAddress: _fanAddress
        });

        fans.push(fan);

        ///@dev - Emit event for creating a Fan
        emit FanCreated(id, _fanId, _monthYear, _earningsAmount, _currency);
    }

    //               ====== UPDATES ======

    // REVENUES

    /**
     * @notice - Updates existing Revenues for a given publication and month/year
     * @param _publicationId - Lens Publication ID of publication
     * @param _monthYear - Month and Year of revenues
     * @param _earnings - JSON string of earnings by source platform
     */
    function updateExistingRevenues(
        string calldata _publicationId,
        string calldata _monthYear,
        string calldata _earnings
    ) external onlyOwner {
        ///@dev - loop through revenues[] array and find specific entry
        for (uint256 i = 0; i < revenues.length; i++) {
            if (
                ///@dev - Solidity can't directly compare strings, so compare hashes
                keccak256(abi.encode(_publicationId)) ==
                keccak256(abi.encode(revenues[i].projectId)) &&
                keccak256(abi.encode(_monthYear)) ==
                keccak256(abi.encode(revenues[i].monthYear))
            ) {
                ///@dev - Update earnings
                revenues[i].earnings = _earnings;
            } else {
                ///@dev - If either projectID or monthYear do not exist, revert transaction
                revert(
                    "Publication ID or MonthYear do not exist, create a new Revenue"
                );
            }
        }

        emit RevenuesUpdated(_publicationId, _monthYear, _earnings);
    }

    // Artists
    /**
     * @notice - Updates existing artist address
     * @param _profileId - Lens Profile ID of artist
     * @param _artistAddress - Wallet of artist
     */
    function updateExistingArtistAddress(
        string calldata _profileId,
        address _artistAddress
    ) external onlyOwner {
        ///@dev - loop through artists[] array and find specific entry
        for (uint256 i = 0; i < revenues.length; i++) {
            if (
                ///@dev - Solidity can't directly compare strings, so compare hashes
                keccak256(abi.encode(_profileId)) ==
                keccak256(abi.encode(artists[i].profileId)) &&
                keccak256(abi.encode(_artistAddress)) ==
                keccak256(abi.encode(artists[i].artistAddress))
            ) {
                ///@dev - Update Artist Address
                artists[i].artistAddress = _artistAddress;
            } else {
                ///@dev - If either artistId or artistAddress do not exist, revert transaction
                revert(
                    "Artist ID or Artist Address does not exist or incorrect"
                );
            }
        }

        emit ArtistAddressUpdated(_profileId, _artistAddress);
    }

    // Publications

    /**
     * @notice - Updates existing publication's Superfluid Index
     * @param _publicationId - Lens Publication ID of publication
     * @param _artistId - Lens Profile ID of artist
     * @param _sfIndexId - New Superfluid Index ID
     */
    function updatePublicationSFIndexID(
        string calldata _publicationId,
        string calldata _artistId,
        string calldata _sfIndexId
    ) external onlyOwner {
        ///@dev - loop through publications[] array and find specific entry
        for (uint256 i = 0; i < publications.length; i++) {
            if (
                ///@dev - Solidity can't directly compare strings, so compare hashes
                keccak256(abi.encode(_publicationId)) ==
                keccak256(abi.encode(publications[i].publicationId)) &&
                keccak256(abi.encode(_artistId)) ==
                keccak256(abi.encode(publications[i].artistId))
            ) {
                ///@dev - Update Publication's Superfluid Index
                publications[i].sfIndexId = _sfIndexId;
            } else {
                revert("Publication ID or Artist ID invalid");
            }
        }

        emit PublicationSFIndexIDUpdated(_publicationId, _artistId, _sfIndexId);
    }

    /**
     * @notice - Update existing publication's profit distribution %
     * @param _publicationId - Lens Publication ID of publication
     * @param _artistId - Lens Profile ID of artist
     * @param _pctProfitDist - Percentage of profit that will be distributed to fans
     */
    function updatePublicationProfitDistribution(
        string calldata _publicationId,
        string calldata _artistId,
        uint256 _pctProfitDist
    ) external onlyOwner {
        ///@dev - loop through publications[] array and find specific entry
        for (uint256 i = 0; i < publications.length; i++) {
            if (
                ///@dev - Solidity can't directly compare strings, so compare hashes
                keccak256(abi.encode(_publicationId)) ==
                keccak256(abi.encode(publications[i].publicationId)) &&
                keccak256(abi.encode(_artistId)) ==
                keccak256(abi.encode(publications[i].artistId))
            ) {
                ///@dev - Update Publication's Superfluid Index
                publications[i].pctProfitToDistribute = _pctProfitDist;
            } else {
                revert("Publication ID or Artist ID invalid");
            }
        }

        emit PublicationProfitDistributionUpdated(
            _publicationId,
            _artistId,
            _pctProfitDist
        );
    }

    /**
     * @notice Update Publication's profit distribution per fan
     * @param _publicationId - Lens Publication ID of publication
     * @param _artistId - Lens Profile ID of artist
     * @param _pctDistPerShare - Percentage of profit will be distributed per fan
     */
    function updatePublicationDistributionPerShare(
        string calldata _publicationId,
        string calldata _artistId,
        uint256 _pctDistPerShare
    ) external onlyOwner {
        ///@dev - loop through publications[] array and find specific entry
        for (uint256 i = 0; i < publications.length; i++) {
            if (
                ///@dev - Solidity can't directly compare strings, so compare hashes
                keccak256(abi.encode(_publicationId)) ==
                keccak256(abi.encode(publications[i].publicationId)) &&
                keccak256(abi.encode(_artistId)) ==
                keccak256(abi.encode(publications[i].artistId))
            ) {
                ///@dev - Update Publication's Share Percentage
                publications[i].pctToDistributePerShare = _pctDistPerShare;
            }

            emit PublicationDistributionPerShareUpdated(
                _publicationId,
                _artistId,
                _pctDistPerShare
            );
        }
    }

    // FANS
    
    /**
     * @notice Update a fan's earnings for a given publication at a given month/year
     * @param _fanId - Lens Profile ID of fan
     * @param _publicationId - Lens Publication ID of publication
     * @param _monthYear - Month and Year of earnings (MM/YYYY Format)
     * @param _earningsAmount - Amount of earnings of given publication at month/year
     * @param _currency - Currency amount is denoted in
     */
    function updateFanBalance(
        string calldata _fanId,
        string calldata _publicationId,
        string calldata _monthYear,
        uint256 _earningsAmount,
        string calldata _currency
    ) external onlyOwner {
        ///@dev - loop through fans[] array and find specific entry
        for (uint256 i = 0; i < fans.length; i++) {
            if (
                ///@dev - Solidity can't directly compare strings, so compare hashes
                keccak256(abi.encode(_fanId)) ==
                keccak256(abi.encode(fans[i].fanId)) &&
                keccak256(abi.encode(_publicationId)) ==
                keccak256(abi.encode(fans[i].publicationId))
            ) {
                ///@dev - Update Fan's Earnings
                fans[i].monthYear = _monthYear;
                fans[i].earningsAmount = _earningsAmount;
                fans[i].currency = _currency;
            }

            emit FanBalanceUpdated(
                _fanId,
                _publicationId,
                _monthYear,
                _earningsAmount,
                _currency
            );
        }
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