pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract testNft is Ownable, ERC1155 {
    using SafeERC20 for IERC20;

    struct TokenInfo {
        uint256 price;
        address tokenAddress;
        bool allowMint;
        bool pauseMint;
    }

    struct BoughtToken {
        uint256 tokenId;
        address tokenAddress;
        uint256 price;
    }

    TokenInfo[] public tokensInfo;
    mapping(address => BoughtToken[]) public userToken;

    event Mint(
        uint256 indexed tokenId,
        address indexed minter,
        uint256 price
    );

    constructor(
        string memory _name
    ) ERC1155(_name) {}

    /// @notice Mint token
    function mint(uint256 tokenId) public {

        TokenInfo storage tokenInfo = tokensInfo[tokenId];

        require(tokenInfo.allowMint, "Mint not allowed");
        require(!tokenInfo.pauseMint, "Mint paused");
        require(IERC20(tokenInfo.tokenAddress).balanceOf(_msgSender()) >= tokenInfo.price, "Insufficient balance");

        BoughtToken memory boughtToken = BoughtToken(tokenId, tokenInfo.tokenAddress, tokenInfo.price);

        IERC20(tokenInfo.tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenInfo.price
        );

        _mint(_msgSender(), tokenId, 1, "");
        userToken[_msgSender()].push(boughtToken);
        emit Mint(tokenId, _msgSender(), tokenInfo.price);
    }


    /// @notice disallow mint
    function disallowMint(uint256 tokenId) external onlyOwner {
        tokensInfo[tokenId].allowMint = false;
    }

    /// @notice pause mint
    function pauseMint(uint256 tokenId) external onlyOwner {
        tokensInfo[tokenId].pauseMint = true;
    }

    /// @notice resume mint
    function resumeMint(uint256 tokenId) external onlyOwner {
        tokensInfo[tokenId].pauseMint = false;
    }

    /// @notice change tokenAddress for token
    function changeTokenAddress(uint256 tokenId, address tokenAddress) external onlyOwner {
        tokensInfo[tokenId].tokenAddress = tokenAddress;
    }

    /// @notice create token
    function createToken(uint256 price, address tokenAddress) external onlyOwner {
        TokenInfo memory tokenInfo = TokenInfo(price, tokenAddress, true, false);
        tokensInfo.push(tokenInfo);
    }

    /// @notice withdraws tokens from marketplace
    function withdrawExtraTokens(
        address token,
        uint256 amount,
        address withdrawTo
    ) external onlyOwner {
        IERC20(token).safeTransfer(withdrawTo, amount);
    }

}