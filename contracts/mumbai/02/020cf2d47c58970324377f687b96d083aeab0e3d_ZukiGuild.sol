// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IGuildNFTCore.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC721.sol";

contract ZukiGuild is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    IGuildNFTCore public nftCore;
    IERC20 public nftToken;
    IERC721 public nft;
    address public feeWallet;

    event CreateGuild(
        uint256 indexed tokenId,
        address buyer,
        uint256 fee,
        uint256 level
    );
    mapping(uint256 => uint256) public levels;
    mapping(address => uint256) public guilds;
    constructor(
        address payable _feeWallet,
        address _nft,
        IERC20 _nftToken
    ) {
        nftCore = IGuildNFTCore(_nft);
        nft = IERC721(_nft);
        feeWallet = _feeWallet;
        nftToken = _nftToken;
        levels[1] = 10000 ether;
        levels[2] = 25000 ether;
        levels[3] = 50000 ether;
        levels[4] = 100000 ether;
        levels[5] = 200000 ether;
    }

    function setLevel(uint256 _level, uint256 _fee) external onlyOwner {
        levels[_level] = _fee;
    }

    function setNFTToken(IERC20 _address) external onlyOwner {
        nftToken = _address;
    }

    function setNFT(address _address) external onlyOwner {
        nft = IERC721(_address);
        nftCore = IGuildNFTCore(_address);
    }

    function setFeeWallet(address payable _wallet) external onlyOwner {
        feeWallet = _wallet;
    }

    /**
     * @dev Merge NFT
     */
    function createGuild(string memory name, uint256 levelGuild)
        public
        nonReentrant
        whenNotPaused
    {
        require(
            nftToken.allowance(_msgSender(), address(this)) >=
                levels[levelGuild],
            "Token allowance too low"
        );
        require(levels[levelGuild] > 0, "Level not correct");
        require(guilds[_msgSender()] == 0, "Already have a guild");
        nftToken.transferFrom(_msgSender(), feeWallet, levels[levelGuild]);
        uint256 tokenId = nftCore.getNextNFTId();
        nftCore.safeMintNFT(_msgSender(), tokenId);
        NFTItem memory nftItem = NFTItem(
            tokenId,
            name,
            levelGuild,
            block.timestamp
        );
        nftCore.setNFTFactory(nftItem, tokenId);
        guilds[_msgSender()] = tokenId;
        emit CreateGuild(tokenId, _msgSender(), levels[levelGuild], levelGuild);
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}