/**
 *Submitted for verification at polygonscan.com on 2023-05-13
*/

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenSale {
    address payable public contractOwner;
    address payable public marketing;
    uint256 public tokenPrice;
    uint256 public referralBonusPercentage;
    mapping(address => bool) public hasUsedReferral;
    IERC20 public token;

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensWithdrawn(address indexed receiver, uint256 amount);
    event TokenPriceSet(uint256 newTokenPrice);
    event ReferralBonusPaid(address indexed referrer, uint256 amount);

    constructor(
        uint256 _tokenPrice,
        uint256 _referralBonusPercentage,
        address _tokenAddress,
        address _marketing
    ) {
        contractOwner = payable(msg.sender);
        tokenPrice = _tokenPrice;
        referralBonusPercentage = _referralBonusPercentage;
        token = IERC20(_tokenAddress);
        marketing = payable(_marketing);
    }

    function buyTokens(address payable referralAddress) external payable {
        uint256 tokensToBuy = msg.value * tokenPrice;

        // Calculate referral bonus
        uint256 referralBonus = 0;
        if (
            !hasUsedReferral[msg.sender] &&
            referralAddress != address(0) &&
            referralAddress != msg.sender
        ) {
            referralBonus = (tokensToBuy * referralBonusPercentage) / 100;
            hasUsedReferral[msg.sender] = true;
            emit ReferralBonusPaid(referralAddress, referralBonus);
        }

        uint256 totalTokens = tokensToBuy + referralBonus;

        require(totalTokens > 0, "No tokens to buy");

        // Transfer tokens to the buyer
        require(token.transfer(msg.sender, totalTokens), "Token transfer failed");

        emit TokensPurchased(msg.sender, totalTokens);
    }

    function withdrawEther() external {
        require(address(this).balance > 0, "No balance to withdraw");

        if (msg.sender == contractOwner) {
            uint256 paymentAmount = address(this).balance;
            contractOwner.transfer(paymentAmount / 2);
            marketing.transfer(paymentAmount / 2);
        } else {
            revert("Only contract owner can withdraw");
        }
    }

    function withdrawTokens(uint256 amount) external {
        require(
            msg.sender == contractOwner,
            "Only contract owner can withdraw tokens"
        );
        require(amount > 0, "Invalid amount");

        require(token.transfer(msg.sender, amount), "Token transfer failed");

        emit TokensWithdrawn(msg.sender, amount);
    }

    function setTokenPrice(uint256 newTokenPrice) external {
        require(
            msg.sender == contractOwner,
            "Only contract owner can set token price"
        );

        tokenPrice = newTokenPrice;

        emit TokenPriceSet(newTokenPrice);
    }
}