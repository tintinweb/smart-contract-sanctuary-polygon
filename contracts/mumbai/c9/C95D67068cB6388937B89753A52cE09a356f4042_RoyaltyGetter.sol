/**
 *Submitted for verification at polygonscan.com on 2023-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IFinalTest {

      function lastTokenIdTransfer() external view returns (uint);

      function ownerOf(uint256 tokenId) external view returns (address);

      function totalSupply() external  view  returns (uint256);

      function tokensOfOwner(address owner) external view returns (uint256[] memory);

          function balanceOf(address owner) external view returns (uint256 balance);




}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/RoyaltyGetter.sol


pragma solidity ^0.8.17;



contract RoyaltyGetter is Ownable {
    IFinalTest Collection;

    uint256 public TR1;
    uint256 public TR2;

    mapping(uint256 => uint256) public TokenIdsLastClaimedAtTR1;
    mapping(uint256 => uint256) public TokenIdsLastClaimedAtTR2;


    constructor(address _collection) {
        Collection = IFinalTest(_collection);

    }

  

    /**
     * Insert full of partial array of your tokenIds. Can be obtain by tokensOfOwner(). For full royalties array length must be
     equal to your balanceOf()
     */
    function getYourRoyaltyForGrantedArray(uint256[] memory _yourTokenIds) public {
        require(
            checkOwnershipOfTokens(msg.sender, _yourTokenIds),
            "you're not owner of these tokens at all"
        );

        uint256 amountToPayout;
        for (uint256 i = 0; i < Collection.balanceOf(msg.sender); i++) {
            if (_yourTokenIds[i] <= 1000) {
                amountToPayout +=
                    (TR1 - TokenIdsLastClaimedAtTR1[_yourTokenIds[i]]) /
                    (Collection.totalSupply());
                TokenIdsLastClaimedAtTR1[_yourTokenIds[i]] = TR1;
            }

            if (_yourTokenIds[i] > 1000 && _yourTokenIds[i] <= 4000) {
                amountToPayout +=
                    (6 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
                TokenIdsLastClaimedAtTR2[_yourTokenIds[i]] = TR2;
            }

            if (_yourTokenIds[i] > 4000) {
                amountToPayout +=
                    (4 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
                TokenIdsLastClaimedAtTR2[_yourTokenIds[i]] = TR2;
            }
        }

        (bool os, ) = payable(msg.sender).call{value: amountToPayout}("");
        require(os);
    }

    

    function checkOwnershipOfTokens(
        address _who,
        uint256[] memory _yourTokenIds
    ) public view returns (bool) {
        for (uint256 i = 0; i < Collection.balanceOf(_who); i++) {
            if (Collection.ownerOf(_yourTokenIds[i]) != _who) {
                return false;
            }
        }
        return true;
    }

    /**
     * Insert full of partial array of your tokenIds. Can be obtain by tokensOfOwner(). For full royalties array length must be
     equal to your balanceOf()
     */
    function calculateAvailableRoyaltiesForGrantedArray(
        uint256[] memory _yourTokenIds
    ) public view returns (uint256) {
        require(
            checkOwnershipOfTokens(msg.sender, _yourTokenIds),
            "you're not owner of these tokens at all"
        );

        uint256 amountToPayout;
        for (uint256 i = 0; i < Collection.balanceOf(msg.sender); i++) {
            if (_yourTokenIds[i] <= 1000) {
                amountToPayout +=
                    (TR1 - TokenIdsLastClaimedAtTR1[_yourTokenIds[i]]) /
                    (Collection.totalSupply());
            }

            if (_yourTokenIds[i] > 1000 && _yourTokenIds[i] <= 4000) {
                amountToPayout +=
                    (6 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
            }

            if (_yourTokenIds[i] > 4000) {
                amountToPayout +=
                    (4 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
            }
        }

        return amountToPayout;
    }

    receive() external payable {
        if (Collection.lastTokenIdTransfer() == 1) {
            TR1 += msg.value;
        }

        if (Collection.lastTokenIdTransfer() == 2) {
            TR2 += msg.value;
        }
    }

    //for emergency reasons
    function getBalance() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}