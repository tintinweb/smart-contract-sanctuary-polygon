// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract LpLocker {
    struct LockedToken {
        address token;
        uint256 amount;
        uint256 unlockTime;
        address owner;
        string tokenName;
        uint8 decimals;
        string logoLink;
        string projectName;
        string projectSymbol;
        string projectDescription;
        string projectLogoLink;
    }

    LockedToken[] public allLockedLP;
    mapping(address => LockedToken[]) public lockedTokens;

    function lockERC20(
        address _token,
        uint256 _amount,
        uint256 _unlockTime,
        string memory _tokenName,
        uint8 _decimals,
        string memory _logoLink
    ) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        LockedToken memory lockedToken = LockedToken({
            token: _token,
            amount: _amount,
            unlockTime: _unlockTime,
            owner: msg.sender,
            tokenName: _tokenName,
            decimals: _decimals,
            logoLink: _logoLink,
            projectName: "",
            projectSymbol: "",
            projectDescription: "",
            projectLogoLink: ""
        });

        lockedTokens[_token].push(lockedToken);
    }

    function lockLP(
        address _token,
        uint256 _amount,
        uint256 _unlockTime,
        string memory _projectName,
        string memory _projectSymbol,
        string memory _projectDescription,
        string memory _projectLogoLink
    ) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        LockedToken memory lockedToken = LockedToken({
            token: _token,
            amount: _amount,
            unlockTime: _unlockTime,
            owner: msg.sender,
            tokenName: "",
            decimals: 0,
            logoLink: "",
            projectName: _projectName,
            projectSymbol: _projectSymbol,
            projectDescription: _projectDescription,
            projectLogoLink: _projectLogoLink
        });

        lockedTokens[_token].push(lockedToken);
        allLockedLP.push(lockedToken);
    }

    function getLockedTokens(address _token)
        public
        view
        returns (LockedToken[] memory)
    {
        return lockedTokens[_token];
    }

    function withdraw(address _token, uint256 _index) public {
        LockedToken[] storage lockedTokenList = lockedTokens[_token];

        require(_index < lockedTokenList.length, "Invalid index");

        LockedToken storage lockedToken = lockedTokenList[_index];

        require(msg.sender == lockedToken.owner, "Only the owner can withdraw");
        require(
            block.timestamp >= lockedToken.unlockTime,
            "Tokens are still locked"
        );

        require(
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                lockedToken.amount
            ),
            "Transfer failed"
        );

        lockedTokenList[_index] = lockedTokenList[lockedTokenList.length - 1];
        lockedTokenList.pop();
    }
}