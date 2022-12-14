// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokneId) external view returns (address owner);
}

contract payment is Ownable {
    address public NFTContractAddress; // NFT contract address
    uint256 public amount; // amount of each nft 0 at the time of deployment

    IERC721 contractInstance; // ERC721 contract instance

    uint256 public cappedSupply; // capped supply 5000
    uint256 public mintedSupply; // minted supply 0 at deployment time
    uint256 public transactionCount; // in case of public sale
    uint256 public mintLimit; // in case of pre sale mint and whitelist mint

    // minting durations
    uint256 public presaleTime; // starting time of presale
    uint256 public whitelistTime; // starting time of whitelist
    uint256 public publicsaleTime; // starting time of public sale

    uint256 public presaleDuration; // duration of presale mint
    uint256 public whitelistDuration; // duration of whitelist mint
    uint256 public publicsaleDurattion; // duration of public sale mint

    address public withdrawAddress; // address who can withdraw eth

    mapping(address => uint256) public mintBalance; // in case of presale mint and whitlist mint

    event WithdrawETH(uint256 indexed amount, address indexed to); // withdraw eth event
    event Airdrop(address[] indexed to, uint256[] indexed tokenId);
    event PresaleMint(address indexed to, uint256[] indexed tokenId);
    event WhitelistMint(address indexed to, uint256[] indexed tokenId);
    event PublicSale(address indexed to, uint256[] indexed tokenId);

    event MintingDuration(
        uint256 indexed presaleDuration,
        uint256 indexed whitelistDuration,
        uint256 indexed publicsaleDuration
    );
    event MintingStartingTime(
        uint256 indexed presaleTime,
        uint256 indexed whitelistTime,
        uint256 indexed publicsaleTime
    );

    event CappedSupply(address indexed owner, uint256 indexed supply);
    event PerTransactionCount(address indexed owner, uint256 indexed count);
    event MintingLimit(address indexed owner, uint256 indexed limit);
    event ContractAddress(
        address indexed owner,
        address indexed contractAddress
    );
    event UpdateAmount(address indexed owner, uint256 indexed amount);
    event WithdrawAddress(
        address indexed owner,
        address indexed withdrawAddress
    );

    constructor() Ownable() {
        NFTContractAddress = 0xFF041a2c30abD984b19c11A250887782aAD1e275;
        contractInstance = IERC721(NFTContractAddress);

        amount = 0 ether;
        cappedSupply = 5;
        mintedSupply = 0;
        transactionCount = 5;
        mintLimit = 5;

        presaleTime = 1670853076; // presale 23-12-22 00:00:00
        whitelistTime = 1670893169; // whitelist mint 23-12-22 00:15:00
        publicsaleTime = 1679854169; // public sale 23-12-22 01:00:00

        presaleDuration = 15 minutes;
        whitelistDuration = 1 hours;
        publicsaleDurattion = 1825 days;

        withdrawAddress = msg.sender;
    }

    function mint(
        address to,
        uint256[] memory tokenId,
        bytes32 signedMessage,
        bytes memory signature
    ) public payable {
        require(
            msg.sender == recoverSigner(signedMessage, signature),
            "singature and msg.sender are not same"
        );
        require(msg.value == tokenId.length * amount, "invalid amount");
        if (
            block.timestamp >= presaleTime &&
            block.timestamp <= presaleTime + presaleDuration
        ) {
            require(
                mintedSupply <= cappedSupply,
                "can't mint capped limit reached"
            );
            require(
                mintBalance[msg.sender] <= mintLimit,
                "minting limit already reached"
            );
            require(
                tokenId.length + mintBalance[msg.sender] <= mintLimit,
                "cannot mint more than the minting limit"
            );
            require(
                mintedSupply + tokenId.length <= cappedSupply,
                "cannot mint capped limit reached"
            );
            _mint(to, tokenId);
            emit PresaleMint(to, tokenId);
        } else if (
            block.timestamp >= whitelistTime &&
            block.timestamp <= whitelistTime + whitelistDuration
        ) {
            require(
                mintedSupply <= cappedSupply,
                "can't mint capped limit reached"
            );
            require(
                mintBalance[msg.sender] <= mintLimit,
                "minting limit already reached"
            );
            require(
                tokenId.length + mintBalance[msg.sender] <= mintLimit,
                "cannot mint more than the minting limit"
            );
            require(
                mintedSupply + tokenId.length <= cappedSupply,
                "cannot mint capped limit reached"
            );
            _mint(to, tokenId);
            emit WhitelistMint(to, tokenId);
        } else if (
            block.timestamp >= publicsaleTime &&
            block.timestamp <= publicsaleTime + publicsaleDurattion
        ) {
            require(
                mintedSupply <= cappedSupply,
                "can't mint capped limit reached"
            );
            require(
                tokenId.length <= transactionCount,
                "cannot mint more than 5 in each transaction"
            );
            require(
                mintedSupply + tokenId.length <= cappedSupply,
                "cannot mint capped limit reached"
            );
            _mint(to, tokenId);
            emit PublicSale(to, tokenId);
        } else {
            revert("minting not started or already finished");
        }
    }

    function setDurations(
        uint256 _presaleDuration,
        uint256 _whitelistDuration,
        uint256 _publicsaleDuration
    ) public onlyOwner {
        // require(
        //     presaleTime + _presaleDuration == whitelistTime &&
        //         whitelistTime + _whitelistDuration == _publicsaleDuration,
        //     "invlid time duration"
        // );
        presaleDuration = _presaleDuration;
        whitelistDuration = _whitelistDuration;
        publicsaleDurattion = _publicsaleDuration;
        emit MintingDuration(
            presaleDuration,
            whitelistDuration,
            publicsaleDurattion
        );
    }

    function setTime(
        uint256 _presaleTime,
        uint256 _whitelistTime,
        uint256 _publicsaleTime
    ) public onlyOwner {
        require(
            _presaleTime != _whitelistTime && _whitelistTime != _publicsaleTime,
            "Time of each slot cannot be same"
        );
        require(
            _presaleTime < _whitelistTime && _whitelistTime < _publicsaleTime,
            "invlalid time for each slot"
        );
        presaleTime = _presaleTime;
        whitelistTime = _whitelistTime;
        publicsaleTime = _publicsaleTime;
        emit MintingStartingTime(presaleTime, whitelistTime, publicsaleTime);
    }

    // function airDrop(
    //     address[] memory to,
    //     uint256[][] memory tokenId
    // ) public onlyOwner {
    //     require(
    //         to.length == tokenId.length,
    //         "length should be same for addresses and tokenIds"
    //     );

    //     for (uint256 i = 0; i < to.length; i++) {
    //         require(
    //             mintedSupply + tokenId[i].length <= cappedSupply,
    //             "capped value reached"
    //         );
    //         for (uint256 j = 0; j < tokenId[i].length; j++) {
    //             contractInstance.mint(to[i], tokenId[i][j]);
    //             mintedSupply++;
    //         }
    //     }
    // }

    function airdrop(
        address[] memory to,
        uint256[] memory tokenId
    ) public onlyOwner {
        require(
            to.length == tokenId.length,
            "length of token id and address should be same"
        );
        require(
            mintedSupply + tokenId.length <= cappedSupply,
            "capped value rached "
        );
        for (uint256 i = 0; i < to.length; i++) {
            require(
                mintedSupply <= cappedSupply,
                "capped value reached can't mint"
            );
            contractInstance.mint(to[i], tokenId[i]);
            mintedSupply++;
        }
        emit Airdrop(to, tokenId);
    }

    // function setTimeDurations(uint256[] memory _time) public onlyOwner {
    //     require(_time.length == 3, "invalid time slots");
    //     require(
    //         _time[0] + 15 minutes == _time[1] && _time[1] + 1 hours == _time[2],
    //         "invlaid time for the slots"
    //     );
    //     presaleTime = _time[0];
    //     whitelistTime = _time[1];
    //     publicsaleTime = _time[2];
    // }

    function updateCappedValue(uint256 value) public onlyOwner {
        require(value >= mintedSupply, "invlid capped value");
        require(value != 0, "capped value cannot be zero");
        cappedSupply = value;
        emit CappedSupply(msg.sender, value);
    }

    function updateTransactionCount(uint256 count) public onlyOwner {
        require(count != 0, "cannot set to zero");
        transactionCount = count;
        emit PerTransactionCount(msg.sender, count);
    }

    function updateMintLimit(uint256 limit) public onlyOwner {
        require(limit != 0, "cannot set to zero");
        mintLimit = limit;
        emit MintingLimit(msg.sender, limit);
    }

    function updateNFTAddress(address _address) public onlyOwner {
        require(
            _address != address(0),
            "address can't be set to address of zero"
        );
        NFTContractAddress = _address;
        contractInstance = IERC721(NFTContractAddress);
    }

    function updateAmount(uint256 _amount) public onlyOwner {
        require(_amount != 0, "invalid amount");
        amount = _amount;
        emit UpdateAmount(msg.sender, _amount);
    }

    function updateWithdrawAddress(address _withdrawAddress) public onlyOwner {
        require(_withdrawAddress != address(0), "cannot be zero address");
        withdrawAddress = _withdrawAddress;
        emit WithdrawAddress(msg.sender, _withdrawAddress);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return contractInstance.ownerOf(tokenId);
    }

    function withdraw(uint256 _amount) public onlyOwner returns (bool) {
        require(address(this).balance >= _amount, "invalid amount");
        (bool success, ) = payable(withdrawAddress).call{value: _amount}("");
        emit WithdrawETH(_amount, withdrawAddress);
        return success;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function _mint(address _to, uint256[] memory _tokenId) internal {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            contractInstance.mint(_to, _tokenId[i]);
            mintedSupply++;
            mintBalance[msg.sender]++;
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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