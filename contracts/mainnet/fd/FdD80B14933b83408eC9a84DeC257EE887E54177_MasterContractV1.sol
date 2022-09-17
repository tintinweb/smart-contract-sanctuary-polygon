/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// File: ICToken.sol



pragma solidity ^0.8.4;

interface ICToken {
    function name() external view returns (string memory);
  function maxSupply() external view returns (uint256);
  function claim(address wallet, uint256 tokenAmount) external;
  function pay(uint256) external;
  function treasuryWallet() external view returns (address);
}

// File: ICryptoCarpinchos.sol



pragma solidity ^0.8.4;

interface ICryptoCarpinchos {
    function ownerOf(uint256 tokenId) external view returns (address);

    function mintingDatetime(uint256 tokenId) external view returns (uint256);

    function usdtAvailable(uint256 tokenId) external view returns (uint256);

    function usdtNotLocked(uint256 tokenId) external view returns (uint256);

    function lockUsdt(uint256 tokenId, uint256 amount) external;

    function finishFight(
        uint256 tokenId,
        uint256 amount,
        bool wins
    ) external;

    function payFee() external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// File: masterContractV1.sol


// solhint-disable-next-line
pragma solidity 0.8.12;





contract MasterContractV1 is ReentrancyGuard, Ownable {
    address public CCAddress;
    address public CTokenAddress;

    address public secret;

    uint256 public timeCounter = 1 days; 
    uint256 public matchsCreated;

    mapping(uint256 => uint256) public lastClaim;
    mapping(uint256 => uint256) public matchsIndex;
    mapping(uint256 => matchStruct) public matchByToken;
    mapping(uint256 => tokenStats) public tokenData;

    struct matchStruct {
        uint256 id;
        uint256 tokenId;
        uint256 price;
        uint256 createdAt;
        address creator;
    }

    struct tokenStats {
        uint256 wins;
        uint256 loses;
    }

    ICryptoCarpinchos CCInterface;
    ICToken CTokenInterface;

    event MATCH_CREATED(uint256 tokenId, uint256 price, uint256 timestamp);
    event MATCH_ACCEPTED(
        uint256 tokenId,
        uint256 oponent,
        uint256 price,
        uint256 result,
        uint256 timestamp
    );
    event MATCH_CANCELLED(uint256 tokenId, uint256 timestamp);

    constructor(address _CCAddress, address _CTokenAddress) {
        CCAddress = _CCAddress;
        CCInterface = ICryptoCarpinchos(_CCAddress);

        CTokenAddress = _CTokenAddress;
        CTokenInterface = ICToken(_CTokenAddress);
    }

    modifier noZeroAddress(address _address) {
        require(_address != address(0), "No Zero Address");
        _;
    }

    modifier onlyAllowed() {
        require(
            owner() == msg.sender || secret == msg.sender,
            "Ownable: caller is not Allowed"
        );
        _;
    }

    function createMatch(uint256 tokenId, uint256 price) external {
        require(
            CCInterface.ownerOf(tokenId) == msg.sender,
            "Not the token owner"
        );
        require(
            CCInterface.usdtAvailable(tokenId) >= price,
            "Not enough usdt available"
        );

        if (matchByToken[tokenId].price == 0) {
            CTokenInterface.pay(20);
            matchsCreated++;
        }

        matchsIndex[matchsCreated - 1] = tokenId;

        matchByToken[tokenId] = matchStruct({
            id: matchsCreated - 1,
            tokenId: tokenId,
            price: price,
            createdAt: block.timestamp,
            creator: msg.sender
        });    

        CCInterface.lockUsdt(tokenId, price);       

        emit MATCH_CREATED(tokenId, price, block.timestamp);
    }

    function cancelMatch(uint256 tokenId) external {
        require(
            CCInterface.ownerOf(tokenId) == msg.sender,
            "Not the token owner"
        );

        removeMatch(tokenId);

        CCInterface.lockUsdt(tokenId, 0);

        emit MATCH_CANCELLED(tokenId, block.timestamp);
    }

    function fight(
        uint256 tokenId,
        uint256 oponent,
        uint256 num
    ) external onlyAllowed {
        matchStruct memory currentMatch = matchByToken[tokenId];
        uint256 price = currentMatch.price;
        uint256 oponentUsdt = CCInterface.usdtNotLocked(oponent);

        require(oponentUsdt > price, "Not enough USDT available for fighting");
        require(price > 0, "There's no match for this token");

        uint256 result = random(num) % 2;

        if (result == 0) {
            CCInterface.finishFight(tokenId, price - 1 * 10**6, true);
            CCInterface.finishFight(oponent, price, false);
            tokenData[tokenId].wins++;
            tokenData[oponent].loses++;
        } else {
            CCInterface.finishFight(tokenId, price, false);
            CCInterface.finishFight(oponent, price - 1 * 10**6, true);
            tokenData[tokenId].loses++;
            tokenData[oponent].wins++;
        }

        CCInterface.payFee();
        removeMatch(tokenId);

        emit MATCH_ACCEPTED(tokenId, oponent, price, result, block.timestamp);
    }

    function claimCtoken(uint256[] memory tokenIds) external {
        uint256 CTokenAmount;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                CCInterface.ownerOf(tokenIds[i]) == msg.sender,
                "Not your token"
            );

            CTokenAmount += getCTokens(tokenIds[i]);
            lastClaim[tokenIds[i]] = block.timestamp;
        }

        CTokenInterface.claim(msg.sender, CTokenAmount);
    }

    function removeMatch(uint256 tokenId) internal {
        uint256 lastTokenId = matchsIndex[matchsCreated - 1];

        if (lastTokenId != tokenId) {
            uint256 currentIndex = matchByToken[tokenId].id;
            matchsIndex[currentIndex] = lastTokenId;
            matchByToken[lastTokenId].id = currentIndex;
        }

        matchsCreated--;
        delete matchByToken[tokenId];
    }

    function getCTokens(uint256 tokenId) public view returns (uint256) {
        uint256 last = lastClaim[tokenId] != 0
            ? lastClaim[tokenId]
            : CCInterface.mintingDatetime(tokenId);

        uint256 timeFromCreation = (block.timestamp - last) / (timeCounter);

        return 100 * timeFromCreation;
    }

    function getActiveMatchs()
        public
        view
        returns (matchStruct[] memory matchs, tokenStats[] memory results)
    {
        matchs = new matchStruct[](matchsCreated);
        results = new tokenStats[](matchsCreated);

        for (uint256 i; i < matchsCreated; i++) {
            uint256 tokenId = matchsIndex[i];
            matchs[i] = matchByToken[tokenId];
            results[i] = tokenData[tokenId];
        }
    }

    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.timestamp,
                        gasleft(),
                        msg.sender,
                        matchsCreated
                    )
                )
            );
    }

    function setCTokenAddress(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        CTokenAddress = _newAddress;
        CTokenInterface = ICToken(_newAddress);
    }

    function setCCAddress(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        CCAddress = _newAddress;
        CCInterface = ICryptoCarpinchos(_newAddress);
    }

    function setSecret(address _secret)
        external
        onlyOwner
        noZeroAddress(_secret)
    {
        secret = _secret;
    }
}