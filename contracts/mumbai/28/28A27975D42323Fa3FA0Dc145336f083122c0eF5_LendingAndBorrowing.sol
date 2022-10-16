// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "IERC20.sol";
import "SafeMath.sol";

// Set up you contract to convert DAI to USD or ETH to USD
contract LendingAndBorrowing is Ownable {
    address[] public lenders;
    address[] public borrowers;

    mapping(address => mapping(address => uint256)) public tokensLentAmount;
    mapping(address => mapping(address => uint256)) public tokensBorrowedAmount;

    mapping(uint256 => mapping(address => address)) public tokensLent;
    mapping(uint256 => mapping(address => address)) public tokensBorrowed;

    mapping(address => address[]) public tokenToPriceFeed;

    mapping(uint256 => mapping(address => address)) public tokensLentOrBorrowed;

    event Withdraw(
        address sender,
        uint256 amount,
        uint256 tokenToWithdrawInDollars,
        uint256 availableToWithdraw,
        uint256 totalAmountLentInDollars,
        uint256 larTokenToRemove
    );
    event PayDebt(
        address sender,
        int256 index,
        uint256 tokenAmountBorrowed,
        uint256 totalTokenAmountToCollectFromUser,
        address[] borrowers
    );
    event Borrow(
        address sender,
        uint256 amountInDollars,
        uint256 totalAmountAvailableForBorrowInDollars,
        bool userPresent,
        int256 userIndex,
        address[] borrowers,
        uint256 currentUserTokenBorrowedAmount
    );
    event Supply(
        address sender,
        address[] lenders,
        uint256 currentUserTokenLentAmount
    );
    event WithdrawTesting(
        address sender,
        uint256 tokentoWithdrawInDollars,
        uint256 availableToWithdraw
    );
    event BorrowTesting1(
        address sender,
        uint256 amountInDollars,
        uint256 totalAmountAvailableForBorrowInDollars
    );
    event BorrowTesting2(address sender, uint256 balance, uint256 amount);
    event RepayTesting1(address sender, int256 index);
    event RepayTesting2(address sender, uint256 tokenBorrowed);

    struct Token {
        address tokenAddress;
        uint256 LTV;
        uint256 stableRate;
        string name;
    }

    Token[] public tokensForLending;
    Token[] public tokensForBorrowing;

    IERC20 public larToken;

    uint256 public noOfTokensLent = 0;
    uint256 public noOfTokensBorrowed = 0;

    constructor(address _token) {
        larToken = IERC20(_token);
    }

    function addTokensForLending(
        string memory name,
        address tokenAddress,
        uint256 LTV,
        uint256 borrowStableRate
    ) public onlyOwner {
        Token memory token = Token(tokenAddress, LTV, borrowStableRate, name);

        if (!tokenIsAlreadyThere(token, tokensForLending)) {
            tokensForLending.push(token);
        }
    }

    function addTokensForBorrowing(
        string memory name,
        address tokenAddress,
        uint256 LTV,
        uint256 borrowStableRate
    ) public onlyOwner {
        Token memory token = Token(tokenAddress, LTV, borrowStableRate, name);

        if (!tokenIsAlreadyThere(token, tokensForBorrowing)) {
            tokensForBorrowing.push(token);
        }
    }

    function addTokenToPriceFeedMapping(
        address tokenAddress,
        address tokenToUsdPriceFeed
    ) public onlyOwner {
        tokenToPriceFeed[tokenAddress].push(tokenToUsdPriceFeed);
    }

    function getLendersArray() public view returns (address[] memory) {
        return lenders;
    }

    function getBorrowersArray() public view returns (address[] memory) {
        return borrowers;
    }

    function getTokensForLendingArray() public view returns (Token[] memory) {
        return tokensForLending;
    }

    function getTokensForBorrowingArray() public view returns (Token[] memory) {
        return tokensForBorrowing;
    }

    function lend(address tokenAddress, uint256 amount) public payable {
        require(
            tokenIsAllowed(tokenAddress, tokensForLending),
            "Token is not supported"
        );

        require(amount > 0, "The amount to supply should be greater than 0");

        IERC20 token = IERC20(tokenAddress);

        require(
            token.balanceOf(msg.sender) >= amount,
            "You have insufficient token to supply that amount"
        );

        token.transferFrom(msg.sender, address(this), amount);

        (bool userPresent, int256 userIndex) = isUserPresentIn(
            msg.sender,
            lenders
        );

        if (userPresent) {
            updateUserTokensBorrowedOrLent(
                tokenAddress,
                amount,
                userIndex,
                "lenders"
            );
        } else {
            lenders.push(msg.sender);
            tokensLentAmount[tokenAddress][msg.sender] = amount;
            tokensLent[noOfTokensLent++][msg.sender] = tokenAddress;
        }

        rewardUserToken(msg.sender, tokenAddress, amount);

        emit Supply(
            msg.sender,
            lenders,
            tokensLentAmount[tokenAddress][msg.sender]
        );
    }

    function borrow(uint256 amount, address tokenAddress) public {
        require(
            tokenIsAllowed(tokenAddress, tokensForBorrowing),
            "Token is not supported for borrowing"
        );
        require(amount > 0, "Amount should be greater than 0");

        uint256 totalAmountAvailableForBorrowInDollars = getUserTotalAmountAvailableForBorrowInDollars(
                msg.sender
            );
        uint256 amountInDollars = getAmountInDollars(amount, tokenAddress);

        emit BorrowTesting1(
            msg.sender,
            amountInDollars,
            totalAmountAvailableForBorrowInDollars
        );

        require(
            amountInDollars <= totalAmountAvailableForBorrowInDollars,
            "You don't have enough collateral to borrow this amount"
        );

        IERC20 token = IERC20(tokenAddress);

        emit BorrowTesting2(msg.sender, token.balanceOf(address(this)), amount);

        require(
            token.balanceOf(address(this)) >= amount,
            "We do not have enough of this token for you to borrow."
        );

        token.transfer(msg.sender, amount);

        (bool userPresent, int256 userIndex) = isUserPresentIn(
            msg.sender,
            borrowers
        );

        if (userPresent) {
            updateUserTokensBorrowedOrLent(
                tokenAddress,
                amount,
                userIndex,
                "borrowers"
            );
        } else {
            borrowers.push(msg.sender);
            tokensBorrowedAmount[tokenAddress][msg.sender] = amount;
            tokensBorrowed[noOfTokensBorrowed++][msg.sender] = tokenAddress;
        }

        emit Borrow(
            msg.sender,
            amountInDollars,
            totalAmountAvailableForBorrowInDollars,
            userPresent,
            userIndex,
            borrowers,
            tokensBorrowedAmount[tokenAddress][msg.sender]
        );
    }

    function payDebt(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount should be greater than 0");

        int256 index = indexOf(msg.sender, borrowers);

        emit RepayTesting1(msg.sender, index);
        require(
            index >= 0,
            "User address is not found in the list of borrowers"
        );

        uint256 tokenBorrowed = tokensBorrowedAmount[tokenAddress][msg.sender];

        emit RepayTesting2(msg.sender, tokenBorrowed);

        require(tokenBorrowed > 0, "You  are not owing");
        IERC20 token = IERC20(tokenAddress);

        uint256 totalTokenAmountToCollectFromUser = amount +
            interest(tokenAddress, tokenBorrowed);

        token.transferFrom(
            msg.sender,
            address(this),
            totalTokenAmountToCollectFromUser
        );

        tokensBorrowedAmount[tokenAddress][msg.sender] =
            tokensBorrowedAmount[tokenAddress][msg.sender] -
            amount;

        // Check If all the amount borrowed = 0;
        uint256 totalAmountBorrowed = getTotalAmountBorrowedInDollars(
            msg.sender
        );

        if (totalAmountBorrowed == 0) {
            borrowers[uint256(index)] = borrowers[borrowers.length - 1];
            borrowers.pop();
        }

        emit PayDebt(
            msg.sender,
            index,
            tokenBorrowed,
            totalTokenAmountToCollectFromUser,
            borrowers
        );
    }

    function withdraw(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount should be greater than 0");

        int256 index = indexOf(msg.sender, lenders);
        require(index >= 0, "User address is not found in the list of lenders");

        IERC20 token = IERC20(tokenAddress);

        uint256 tokenToWithdrawInDollars = getAmountInDollars(
            amount,
            tokenAddress
        );
        uint256 availableToWithdraw = getTokenAvailableToWithdraw(msg.sender);

        uint256 totalTokenSuppliedInContract = getTotalTokenSupplied(
            tokenAddress
        );
        uint256 totalTokenBorrowedInContract = getTotalTokenBorrowed(
            tokenAddress
        );

        require(
            amount <=
                (totalTokenSuppliedInContract - totalTokenBorrowedInContract)
        );

        emit WithdrawTesting(
            msg.sender,
            tokenToWithdrawInDollars,
            availableToWithdraw
        );

        require(
            tokenToWithdrawInDollars <= availableToWithdraw,
            "You have used some of your supplies as your collateral. Pay your debt before you can be allowed to withdraw. Thanks"
        );

        uint256 larTokenToRemove = getAmountInDollars(amount, tokenAddress);
        uint256 larTokenBalance = larToken.balanceOf(msg.sender);

        if (larTokenToRemove <= larTokenBalance) {
            larToken.transferFrom(msg.sender, address(this), larTokenToRemove);
        } else {
            larToken.transferFrom(msg.sender, address(this), larTokenBalance);
        }

        token.transfer(msg.sender, amount);

        tokensLentAmount[tokenAddress][msg.sender] =
            tokensLentAmount[tokenAddress][msg.sender] -
            amount;

        uint256 totalAmountLentInDollars = getTotalAmountLentInDollars(
            msg.sender
        );

        emit Withdraw(
            msg.sender,
            amount,
            tokenToWithdrawInDollars,
            availableToWithdraw,
            totalAmountLentInDollars,
            larTokenToRemove
        );

        if (totalAmountLentInDollars <= 0) {
            lenders[uint256(index)] = lenders[lenders.length - 1];
            lenders.pop();
        }
    }

    function getTokenAvailableToWithdraw(address user)
        public
        view
        returns (uint256)
    {
        uint256 totalAmountBorrowedInDollars = getTotalAmountBorrowedInDollars(
            user
        );

        uint256 remainingCollateral = 0;

        if (totalAmountBorrowedInDollars > 0) {
            remainingCollateral = getRemainingCollateral(user);
        } else {
            remainingCollateral = getTotalAmountLentInDollars(user);
        }

        if (remainingCollateral < totalAmountBorrowedInDollars) {
            return 0;
        }

        uint256 availableToWithdraw = remainingCollateral -
            totalAmountBorrowedInDollars;

        return availableToWithdraw;
    }

    function getRemainingCollateral(address user)
        public
        view
        returns (uint256)
    {
        uint256 remainingCollateral = 0;
        for (uint256 i = 0; i < noOfTokensLent; i++) {
            address userLentTokenAddressFound = tokensLent[i][user];

            if (
                userLentTokenAddressFound !=
                0x0000000000000000000000000000000000000000
            ) {
                Token memory currentTokenFound = getTokenFrom(
                    userLentTokenAddressFound
                );
                uint256 tokenAmountLent = tokensLentAmount[
                    userLentTokenAddressFound
                ][user];

                uint256 tokenAmountLentInDollars = getAmountInDollars(
                    tokenAmountLent,
                    userLentTokenAddressFound
                );

                remainingCollateral +=
                    (tokenAmountLentInDollars * currentTokenFound.LTV) /
                    10**18;
            }
        }
        return remainingCollateral;
    }

    function indexOf(address user, address[] memory addressArray)
        public
        returns (int256)
    {
        int256 index = -1;

        for (uint256 i = 0; i < addressArray.length; i++) {
            address currentAddress = addressArray[i];
            if (currentAddress == user) {
                return int256(i);
            }
        }
        return index;
    }

    function getTotalAmountBorrowedInDollars(address user)
        public
        view
        returns (uint256)
    {
        uint256 totalAmountBorrowed = 0;

        for (uint256 i = 0; i < noOfTokensBorrowed; i++) {
            address userBorrowedTokenAddressFound = tokensBorrowed[i][user];

            if (
                userBorrowedTokenAddressFound !=
                0x0000000000000000000000000000000000000000
            ) {
                uint256 tokenAmountBorrowed = tokensBorrowedAmount[
                    userBorrowedTokenAddressFound
                ][user];

                uint256 tokenAmountBorrowedInDollars = getAmountInDollars(
                    tokenAmountBorrowed,
                    userBorrowedTokenAddressFound
                );

                totalAmountBorrowed += tokenAmountBorrowedInDollars;
            }
        }
        return totalAmountBorrowed;
    }

    function getTotalAmountLentInDollars(address user)
        public
        view
        returns (uint256)
    {
        uint256 totalAmountLent = 0;
        for (uint256 i = 0; i < noOfTokensLent; i++) {
            address userLentTokenAddressFound = tokensLent[i][user];

            if (
                userLentTokenAddressFound !=
                0x0000000000000000000000000000000000000000
            ) {
                uint256 tokenAmountLent = tokensLentAmount[
                    userLentTokenAddressFound
                ][user];

                uint256 tokenAmountLentInDollars = getAmountInDollars(
                    tokenAmountLent,
                    userLentTokenAddressFound
                );

                totalAmountLent += tokenAmountLentInDollars;
            }
        }
        return totalAmountLent;
    }

    function interest(address tokenAddress, uint256 tokenBorrowed)
        public
        view
        returns (uint256)
    {
        Token memory token = getTokenFrom(tokenAddress);
        return (tokenBorrowed * token.stableRate) / 10**18;
    }

    function getTokenFrom(address tokenAddress)
        public
        view
        returns (Token memory)
    {
        Token memory token;
        for (uint256 i = 0; i < tokensForBorrowing.length; i++) {
            Token memory currentToken = tokensForBorrowing[i];
            if (currentToken.tokenAddress == tokenAddress) {
                token = currentToken;
                break;
            }
        }
        return token;
    }

    function getUserTotalAmountAvailableForBorrowInDollars(address user)
        public
        view
        returns (uint256)
    {
        // uint256 totalAvailableToBorrow = 0;

        uint256 userTotalCollateralToBorrow = 0;
        uint256 userTotalCollateralAlreadyBorrowed = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            address currentLender = lenders[i];
            if (currentLender == user) {
                for (uint256 j = 0; j < tokensForLending.length; j++) {
                    Token memory currentTokenForLending = tokensForLending[j];
                    uint256 currentTokenLentAmount = tokensLentAmount[
                        currentTokenForLending.tokenAddress
                    ][user];
                    uint256 currentTokenLentAmountInDollar = getAmountInDollars(
                        currentTokenLentAmount,
                        currentTokenForLending.tokenAddress
                    );
                    uint256 availableInDollar = (currentTokenLentAmountInDollar *
                            currentTokenForLending.LTV) / 10**18;
                    userTotalCollateralToBorrow += availableInDollar;
                }
            }
        }

        for (uint256 i = 0; i < borrowers.length; i++) {
            address currentBorrower = borrowers[i];
            if (currentBorrower == user) {
                for (uint256 j = 0; j < tokensForBorrowing.length; j++) {
                    Token memory currentTokenForBorrowing = tokensForBorrowing[
                        j
                    ];
                    uint256 currentTokenBorrowedAmount = tokensBorrowedAmount[
                        currentTokenForBorrowing.tokenAddress
                    ][user];
                    uint256 currentTokenBorrowedAmountInDollar = getAmountInDollars(
                            (currentTokenBorrowedAmount),
                            currentTokenForBorrowing.tokenAddress
                        );

                    userTotalCollateralAlreadyBorrowed += currentTokenBorrowedAmountInDollar;
                }
            }
        }

        return userTotalCollateralToBorrow - userTotalCollateralAlreadyBorrowed;
    }

    function tokenIsBorrowed(address user, address token)
        private
        view
        returns (bool)
    {
        return tokensBorrowedAmount[token][user] != 0;
    }

    function tokenIsAllowed(address tokenAddress, Token[] memory tokenArray)
        private
        pure
        returns (bool)
    {
        if (tokenArray.length > 0) {
            for (uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if (currentToken.tokenAddress == tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }

    function tokenIsAlreadyThere(Token memory token, Token[] memory tokenArray)
        private
        pure
        returns (bool)
    {
        if (tokenArray.length > 0) {
            for (uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if (currentToken.tokenAddress == token.tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }

    function rewardUserToken(
        address user,
        address tokenAddress,
        uint256 amount
    ) private {
        // Send some tokens to the user equivalent to the token amount lent.
        require(amount > 0, "Amount should be greater than 0");

        uint256 amountIndollars = getAmountInDollars(amount, tokenAddress);
        larToken.transfer(user, amountIndollars);
    }

    function getAmountInDollars(uint256 amount, address tokenAddress)
        public
        view
        returns (uint256)
    {
        (
            uint256 dollarPerToken,
            uint256 decimals
        ) = oneTokenEqualsHowManyDollars(tokenAddress);
        uint256 totalAmountInDollars = (amount * dollarPerToken) /
            (10**decimals);
        return totalAmountInDollars;
    }

    function oneTokenEqualsHowManyDollars(address tokenAddress)
        public
        view
        returns (uint256, uint256)
    {
        if (
            tokenAddress == address(0x326C977E6efc84E512bB9C30f76E30c160eD06FB)
        ) {
            address linkToMatic = tokenToPriceFeed[tokenAddress][0];
            AggregatorV3Interface priceFeed1 = AggregatorV3Interface(linkToMatic);

            (, int256 price1, , , ) = priceFeed1.latestRoundData();

            uint256 decimals1 = priceFeed1.decimals();

            address maticToUsd = tokenToPriceFeed[tokenAddress][1];
            AggregatorV3Interface priceFeed2 = AggregatorV3Interface(maticToUsd);

            (, int256 price2, , , ) = priceFeed2.latestRoundData();

            uint256 decimals2 = priceFeed2.decimals();

            return (SafeMath.mul(uint256(price1), uint256(price2)), decimals1 * decimals2);
        } else {
            address tokenToUsd = tokenToPriceFeed[tokenAddress][0];
            AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenToUsd);

            (, int256 price, , , ) = priceFeed.latestRoundData();

            uint256 decimals = priceFeed.decimals();

            return (uint256(price), decimals);
        }
    }

    function updateUserTokensBorrowedOrLent(
        address tokenAddress,
        uint256 amount,
        int256 userIndex,
        string memory lendersOrBorrowers
    ) internal {
        if (
            keccak256(abi.encodePacked(lendersOrBorrowers)) ==
            keccak256(abi.encodePacked("lenders"))
        ) {
            address currentUser = lenders[uint256(userIndex)];

            bool tokenLendedAlready = hasLentOrBorrowedToken(
                currentUser,
                tokenAddress,
                noOfTokensLent,
                "tokensLent"
            );

            if (tokenLendedAlready) {
                tokensLentAmount[tokenAddress][currentUser] =
                    tokensLentAmount[tokenAddress][currentUser] +
                    amount;
            } else {
                tokensLent[noOfTokensLent++][currentUser] = tokenAddress;
                tokensLentAmount[tokenAddress][currentUser] = amount;
            }
        } else if (
            keccak256(abi.encodePacked(lendersOrBorrowers)) ==
            keccak256(abi.encodePacked("borrowers"))
        ) {
            address currentUser = borrowers[uint256(userIndex)];

            bool tokenBorrowedAlready = hasLentOrBorrowedToken(
                currentUser,
                tokenAddress,
                noOfTokensBorrowed,
                "tokensBorrowed"
            );

            if (tokenBorrowedAlready) {
                tokensBorrowedAmount[tokenAddress][currentUser] =
                    tokensBorrowedAmount[tokenAddress][currentUser] +
                    amount;
            } else {
                tokensBorrowed[noOfTokensBorrowed++][
                    currentUser
                ] = tokenAddress;
                tokensBorrowedAmount[tokenAddress][currentUser] = amount;
            }
        }
    }

    function hasLentOrBorrowedToken(
        address currentUser,
        address tokenAddress,
        uint256 noOfTokenslentOrBorrowed,
        string memory _tokensLentOrBorrowed
    ) public view returns (bool) {
        if (noOfTokenslentOrBorrowed > 0) {
            if (
                keccak256(abi.encodePacked(_tokensLentOrBorrowed)) ==
                keccak256(abi.encodePacked("tokensLent"))
            ) {
                for (uint256 i = 0; i < noOfTokensLent; i++) {
                    address tokenAddressFound = tokensLent[i][currentUser];
                    if (tokenAddressFound == tokenAddress) {
                        return true;
                    }
                }
            } else if (
                keccak256(abi.encodePacked(_tokensLentOrBorrowed)) ==
                keccak256(abi.encodePacked("tokensBorrowed"))
            ) {
                for (uint256 i = 0; i < noOfTokensBorrowed; i++) {
                    address tokenAddressFound = tokensBorrowed[i][currentUser];
                    if (tokenAddressFound == tokenAddress) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function isUserPresentIn(address userAddress, address[] memory users)
        private
        pure
        returns (bool, int256)
    {
        if (users.length > 0) {
            for (uint256 i = 0; i < users.length; i++) {
                address currentUserAddress = users[i];
                if (currentUserAddress == userAddress) {
                    return (true, int256(i));
                }
            }
        }

        return (false, -1);
    }

    function getTotalTokenSupplied(address tokenAddres)
        public
        view
        returns (uint256)
    {
        uint256 totalTokenSupplied = 0;
        if (lenders.length > 0) {
            for (uint256 i = 0; i < lenders.length; i++) {
                address curentLender = lenders[i];
                totalTokenSupplied += tokensLentAmount[tokenAddres][
                    curentLender
                ];
            }
        }

        return totalTokenSupplied;
    }

    function getTotalTokenBorrowed(address tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 totalTokenBorrowed = 0;
        if (borrowers.length > 0) {
            for (uint256 i = 0; i < borrowers.length; i++) {
                address curentBorrower = borrowers[i];
                totalTokenBorrowed += tokensBorrowedAmount[tokenAddress][
                    curentBorrower
                ];
            }
        }
        return totalTokenBorrowed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}