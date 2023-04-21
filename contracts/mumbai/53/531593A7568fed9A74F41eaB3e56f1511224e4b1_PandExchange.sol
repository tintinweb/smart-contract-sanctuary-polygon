// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../Struct/DCAPlan.sol";

interface IPandExchange {
    
    event DCAPlanCreated(
        uint256 indexed dcaPlanId,
        address indexed userAddress,
        uint256 creationTimestamp,
        uint256 totalOccurrence,
        uint256 period
    );
    event DCAPlanOccurrenceExecuted(
        uint256 indexed dcaPlanId,
        address indexed userAddress,
        address indexed executorAddress,
        uint256 totalOccurrence,
        uint256 currentOccurrence,
        uint256 nextOccurrenceTimestamp,
        uint256 estimatedMinimumAmountOut,
        address tokenIn,
        address tokenOut,
        uint256 tokenInExchangedAmount,
        uint256 executorsFeeAmount
    );
    event DCAPlanDeleted(
        uint256 indexed dcaPlanId,
        address indexed userAddress
    );
    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event DCAPlanFeeIncreased(
        uint256 indexed dcaPlanId,
        address indexed userAddress,
        uint256 increaseAmount
    );
    event DCAPlanFeeDecreased(
        uint256 indexed dcaPlanId,
        address indexed userAddress,
        uint256 decreaseAmount
    );
    event DCAPlanSlippageTolerancegeUpdated(
        uint256 indexed dcaPlanId,
        address indexed userAddress,
        uint256 oldSlippageTolerance,
        uint256 newSlippageTolerance
    );
    event OwnerFeeUpdated(uint256 oldOwnerFee, uint256 newOwnerFee);
    event AchievementRouterUpdated(
        address indexed oldAchievementRouter,
        address indexed newAchievementRouter
    );

    function createDCAPlan(
        DCAPlan memory _DCAPlanData,
        uint256 _amountOutMinFirstTransaction
    ) external payable returns (uint256);

    function executeDCAPlanOccurrence(
        address _userAddress,
        uint256 _dcaPlanId,
        uint256 _amountOutMin
    ) external;

    function deleteDCAPlan(uint256 _dcaPlanId) external;

    function increaseDCAPlanFee(uint256 _dcaPlanID) external payable;

    function decreaseDCAPlanFee(
        uint256 _dcaPlanID,
        uint256 _decreaseAmount
    ) external;

    function modifyDCAPlanSlippageTolerance(
        uint256 _dcaPlanID,
        uint256 _newSlippage
    ) external;

    function getAllUserDCAPlans(
        address _userAddress
    ) external view returns (DCAPlan[] memory);

    function getUserDCAPlan(
        address _userAddress,
        uint256 _dcaPlanID
    ) external view returns (DCAPlan memory);

    function getUserNumberOfDCAPlans(
        address _userAddress
    ) external view returns (uint256);

    function getAllPendingDCAPlans()
        external
        view
        returns (DCAPlan[] memory, address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../Struct/TokenAchievements.sol";

interface IPandExchangeAchievementRouter {

    function getAchievements(
        address _user
    ) external returns (TokenAchievements memory);

    function addAchievementContract(address _achievementContract) external;

    function removeAchievementContract(address _achievementContract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IRouter01.sol";

interface IRouter02 is IRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// PandExchange is a decentralized application allowing user to perform DCA in a fully decentralized way.
// The application is built on top of the Binance Smart Chain and uses an external swap DApp to perform the swaps.
// The application is built by the PandExchange team.
// For more information, please visit pand.exchange
// Contact us at:
// Telegram: https://t.me/pandexchange
// Twitter: https://twitter.com/pandexchange

pragma solidity 0.8.19;

import "./Interfaces/IPandExchange.sol";
import "./Interfaces/IRouter02.sol";
import "./Interfaces/IERC20.sol";

import "./Interfaces/IPandExchangeAchievementRouter.sol";
import "./Struct/TokenAchievements.sol";

contract PandExchange is IPandExchange {
    /*
        PandExchange is a contract that allows you to exchange your tokens for another token using the DCA method.
        You can create a DCA Plan by calling the createDCAPlan function.
        You can delete a DCA Plan by calling the deleteDCAPlan function.
        You can execute a DCA Plan by calling the executeDCAPlanOccurrence function.
        As you cannot schedule functions executions in contracts, you have to call the executeDCAOperation function manually.
        To reward the users who call the executeDCAOperation function, a fee put during the DCA creation and is then redistributed to the caller, to compensate the gas fees.
        By doing so, this DApp can remain fully decentralized and trustless.
        There is a 0.5% fee of the amount of tokens to be exchanged, given to the contract owner to support the application development.
        All token swap are done using the DEX Router chosen by the user, at the DCA creation.
    */
    address public owner;
    bool public isPaused;

    mapping(address => DCAPlan[]) public usersDCAPlans;
    mapping(address => bool) public hasAnActiveDCA;
    address[] public usersAddresses;

    uint256 public ownerFee5Decimals; //5 decimals (ie 0.5% = 500), maximum 1% fee

    address public achievementRouterAddress;

    constructor() {
        owner = msg.sender;
        isPaused = false;
        ownerFee5Decimals = 500;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Error: Require to be the contract's owner"
        );
        _;
    }

    modifier notPaused() {
        require(!isPaused, "Error: Contract is paused");
        _;
    }

    function createDCAPlan(
        DCAPlan memory _DCAPlanData,
        uint256 _amountOutMinFirstTransaction
    ) external payable notPaused returns (uint256) {
        //Add a DCA Plan to the calling user and take the necessary funds to the contract
        //The funds can be retrieved at all time be cancelling the DCA
        //If one of the two address is address(0), its the chain native token

        uint256 timestamp = block.timestamp;
        uint256 totalAmountOverall = _DCAPlanData.totalOccurrences *
            _DCAPlanData.amountPerOccurrence;

        require(
            _DCAPlanData.periodDays *
                _DCAPlanData.totalOccurrences *
                _DCAPlanData.amountPerOccurrence >
                0,
            "Error: DCA Period, Total Occurrences and Amount Per Occurrence must be all greater than 0"
        );
        require(
            _DCAPlanData.slippageTolerance5Decimals < 100_000,
            "Error: Slippage tolerance must be inferior than 1, with 5 decimals"
        );
        require(
            _DCAPlanData.currentOccurrence == 0,
            "Error: Current occurrence must be 0 at the start"
        );
        require(
            _DCAPlanData.tokenIn != _DCAPlanData.tokenOut,
            "Error: Token In and Token Out must be different"
        );
        if (_DCAPlanData.tokenIn == address(0)) {
            address WETH = IRouter02(_DCAPlanData.exchangeRouterAddress).WETH();
            require(_DCAPlanData.swapPath[0] == WETH, "Error: Wrong path");
        } else if (_DCAPlanData.tokenOut == address(0)) {
            address WETH = IRouter02(_DCAPlanData.exchangeRouterAddress).WETH();
            require(
                _DCAPlanData.swapPath[_DCAPlanData.swapPath.length - 1] == WETH,
                "Error: Wrong path"
            );
        } else {
            require(
                _DCAPlanData.swapPath[0] == _DCAPlanData.tokenIn,
                "Error: Wrong path"
            );
            require(
                _DCAPlanData.swapPath[_DCAPlanData.swapPath.length - 1] ==
                    _DCAPlanData.tokenOut,
                "Error: Wrong path"
            );
        }
        require(
            _DCAPlanData.occurrencesExchangePrices.length == 0,
            "Error: Occurrences Exchange Prices must be empty at the start"
        );

        if (!hasAnActiveDCA[msg.sender]) {
            usersAddresses.push(msg.sender);
            hasAnActiveDCA[msg.sender] = true;
        }

        TokenAchievements memory tokenAchievements = TokenAchievements(0);
        if (achievementRouterAddress != address(0)) {
            tokenAchievements = IPandExchangeAchievementRouter(
                achievementRouterAddress
            ).getAchievements(msg.sender);
        }

        uint256 ownerFee = ((totalAmountOverall * 100_000) *
            ownerFee5Decimals) / 10_000_000_000;
        //the owner fee is reduced by its creationFeeReduction property
        ownerFee =
            (ownerFee * (100 - tokenAchievements.creationFeeReduction)) /
            100;

        _DCAPlanData.tokenInLockedAmount = totalAmountOverall - ownerFee;
        _DCAPlanData.creationTimestamp = timestamp;
        _DCAPlanData.amountPerOccurrence =
            _DCAPlanData.tokenInLockedAmount /
            _DCAPlanData.totalOccurrences;

        usersDCAPlans[msg.sender].push(_DCAPlanData);

        emit DCAPlanCreated(
            usersDCAPlans[msg.sender].length - 1,
            msg.sender,
            timestamp,
            _DCAPlanData.totalOccurrences,
            _DCAPlanData.periodDays
        );
        if (_DCAPlanData.tokenIn != address(0)) {
            //Require the user to approve the transfer beforehand
            bool success = IERC20(_DCAPlanData.tokenIn).transferFrom(
                msg.sender,
                address(this),
                totalAmountOverall
            );
            require(success, "Error: TokenIn TransferFrom failed");
            require(
                msg.value == _DCAPlanData.executorsFeeAmount,
                "Error: Wrong amount of Native Token sent for the fee"
            );
        } else {
            require(
                msg.value ==
                    totalAmountOverall + _DCAPlanData.executorsFeeAmount,
                "Error: Wrong amount of Native Token sent"
            );
        }

        //The first occurrence is executed immediately
        executeDCAPlanOccurrence(
            msg.sender,
            usersDCAPlans[msg.sender].length - 1,
            _amountOutMinFirstTransaction
        );
        //Send the owner fee, a one time fee at the creation of the DCA
        sendFee(owner, _DCAPlanData.tokenIn, ownerFee);

        return timestamp;
    }

    function deleteDCAPlan(uint256 _dcaPlanId) external {
        /*Delete a DCA to free the storage and transfer back to the user the remaining amount of token IN
            address(0) as the IN our OUT token mean that it is Native Token
        */
        DCAPlan[] memory dcaPlan = usersDCAPlans[msg.sender];
        require(
            dcaPlan.length > _dcaPlanId,
            "Error: No DCA with this ID for this user"
        );

        //Delete the DCA from the array
        usersDCAPlans[msg.sender][_dcaPlanId] = dcaPlan[dcaPlan.length - 1];
        usersDCAPlans[msg.sender].pop();

        emit DCAPlanDeleted(_dcaPlanId, msg.sender);

        bool tokenInTransfer = false;
        if (dcaPlan[_dcaPlanId].tokenIn != address(0)) {
            tokenInTransfer = IERC20(dcaPlan[_dcaPlanId].tokenIn).transfer(
                msg.sender,
                dcaPlan[_dcaPlanId].tokenInLockedAmount
            );
            require(
                tokenInTransfer,
                "ERC20 Transfer failed while deleting DCA."
            );
        } else {
            (tokenInTransfer, ) = msg.sender.call{
                value: dcaPlan[_dcaPlanId].tokenInLockedAmount
            }("");
            require(
                tokenInTransfer,
                "Native token Transfer failed while deleting DCA."
            );
        }

        bool feeTransfer = false;
        (feeTransfer, ) = msg.sender.call{
            value: dcaPlan[_dcaPlanId].executorsFeeAmount
        }("");
        require(feeTransfer, "Fee Transfer failed while deleting DCA.");
    }

    function executeDCAPlanOccurrence(
        address _userAddress,
        uint256 _dcaPlanID,
        uint256 _amountOutMin
    ) public notPaused {
        /*  Execute a single occurrence of a single DCA for the user
            Find the right one by the user address and startDate value, which is unique for each DCA of a specific user
            It implies that we must know this exact value, which is done by listening to the DCAPlanCreated event
            A contract that created a DCA can also get this as a return value of the addNewDCAToUser() function
            This function reward the caller with a percentage of the input token traded in an occurrence, to compensate for the gas fees
            Steps :
             - Security checks
               - The DCA must exist
               - The current date must be around startDate + period * currentOccurrence 
               - The currentOccurrence number should be lower than the totalOccurrence (i.e. not completed)
             - Modify the DCAPlan state to reflect the Plan (need to do it 1st to avoid re-entrency attacks)
                - Increment the number of occurrence
                - Modify the lockedAmount of each token
             - Swap the defined amount of tokens, minus the fee, with the swap() function 
             - Send the fee to the caller of the function
             - Send the fee to the address that executed this function
             TODO: 
        */
        DCAPlan[] memory dcaPlans = usersDCAPlans[_userAddress];
        require(
            dcaPlans.length > _dcaPlanID,
            "Error: No DCA with this ID for this user"
        );
        DCAPlan memory userDCA = dcaPlans[_dcaPlanID];
        require(
            userDCA.totalOccurrences > userDCA.currentOccurrence,
            "Error: DCA has already been completed"
        );
        require(
            block.timestamp >=
                userDCA.creationTimestamp +
                    userDCA.periodDays *
                    1 days *
                    userDCA.currentOccurrence,
            "Error: Too soon to execute this DCA"
        );

        usersDCAPlans[_userAddress][_dcaPlanID].currentOccurrence =
            userDCA.currentOccurrence +
            1;

        bool isLastOccurrence = userDCA.totalOccurrences ==
            userDCA.currentOccurrence + 1;

        uint256 tradeAmount = userDCA.amountPerOccurrence;

        if (isLastOccurrence) {
            tradeAmount = userDCA.tokenInLockedAmount;
            usersDCAPlans[_userAddress][_dcaPlanID].tokenInLockedAmount = 0;
        } else {
            usersDCAPlans[_userAddress][_dcaPlanID].tokenInLockedAmount =
                userDCA.tokenInLockedAmount -
                userDCA.amountPerOccurrence;
        }

        uint256[] memory minimumAmountOutArray = IRouter02(
            userDCA.exchangeRouterAddress
        ).getAmountsOut(tradeAmount, userDCA.swapPath);

        usersDCAPlans[_userAddress][_dcaPlanID].occurrencesExchangePrices.push(
            [
                tradeAmount,
                minimumAmountOutArray[minimumAmountOutArray.length - 1]
            ]
        );

        uint256 feeCaller = 0;
        //If the caller is not the user, he will get a fee to compensate for the gas fees
        //The fee is set by the user when he created the DCA
        if (msg.sender != _userAddress) {
            feeCaller =
                userDCA.executorsFeeAmount /
                (userDCA.totalOccurrences - userDCA.currentOccurrence);
        }
        usersDCAPlans[_userAddress][_dcaPlanID].executorsFeeAmount -= feeCaller;

        //Set the timestamp of the next occurrence. 0 if it is the last one (i.e. currentOccurrence == totalOccurrences)
        uint256 nextOccurrenceTimestamp = 0;
        if (userDCA.totalOccurrences > userDCA.currentOccurrence + 1) {
            nextOccurrenceTimestamp =
                _dcaPlanID +
                (userDCA.currentOccurrence + 1) *
                userDCA.periodDays *
                1 days;
        }
        emit DCAPlanOccurrenceExecuted(
            _dcaPlanID,
            _userAddress,
            msg.sender,
            userDCA.totalOccurrences,
            userDCA.currentOccurrence + 1,
            nextOccurrenceTimestamp,
            _amountOutMin,
            userDCA.tokenIn,
            userDCA.tokenOut,
            tradeAmount,
            feeCaller
        );

        //Send the fee to the caller of the function, if any (i.e. if the caller is not the user)
        if (feeCaller > 0) {
            sendFee(msg.sender, address(0), feeCaller);
        }

        //Swap the amount of token minus the fee
        //Out token is directly sent to the user
        swap(
            userDCA.tokenIn,
            userDCA.tokenOut,
            userDCA.swapPath,
            tradeAmount,
            _amountOutMin,
            _userAddress,
            userDCA.exchangeRouterAddress
        );
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _userAddress,
        address _exchangeRouterAddress
    ) private {
        /*
            Swap _tokenIn for _tokenOut using the provided RouterV2 contract
            If _tokenIn is an ERC20 it first gives _amountIn allowance to the router to do the swap
            Then it calls the appropriate function for the swap
            The called Router function depends on the nature of _tokenIn and _tokenOut, if one of them is Native Token or not
        */

        //Case 1: Both tokens are ERC20 tokens
        if (_tokenIn != address(0) && _tokenOut != address(0)) {
            bool success = IERC20(_tokenIn).approve(
                _exchangeRouterAddress,
                _amountIn
            );
            require(success, "ERC20 Transfer failed while approving swap.");
            IRouter02(_exchangeRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountIn,
                    _amountOutMin,
                    _path,
                    _userAddress,
                    block.timestamp
                );
        }
        //Case 2: _tokenIn is Native Token
        else if (_tokenIn == address(0)) {
            IRouter02(_exchangeRouterAddress)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: _amountIn
            }(_amountOutMin, _path, _userAddress, block.timestamp);
        }
        //Case 3: _tokenOut is Native Token
        else {
            bool success = IERC20(_tokenIn).approve(
                _exchangeRouterAddress,
                _amountIn
            );
            require(success, "ERC20 Transfer failed while approving swap.");
            IRouter02(_exchangeRouterAddress)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _amountIn,
                    _amountOutMin,
                    _path,
                    _userAddress,
                    block.timestamp
                );
        }
    }

    function sendFee(
        address _recipient,
        address _tokenFee,
        uint256 _feeAmount
    ) private {
        require(_recipient != address(0), "Error: Invalid recipient address");
        bool success = false;
        if (_tokenFee != address(0)) {
            success = IERC20(_tokenFee).transfer(_recipient, _feeAmount);
            require(success, "ERC20 Transfer failed while sending fee.");
        } else {
            (success, ) = _recipient.call{value: _feeAmount}("");
            require(success, "Native Token Transfer failed while sending fee.");
        }
    }

    function increaseDCAPlanFee(uint256 _dcaPlanID) external payable notPaused {
        /*
            Allow user to increase the total amount of fee stoked in the DCA
        */
        DCAPlan[] memory _dcaPlan = usersDCAPlans[msg.sender];
        require(_dcaPlan.length > _dcaPlanID, "Error: This DCA does not exist");
        require(msg.value > 0, "Error: Fee amount must be higher than 0");
        require(
            _dcaPlan[_dcaPlanID].currentOccurrence <
                _dcaPlan[_dcaPlanID].totalOccurrences,
            "Error: DCA is already finished"
        );
        usersDCAPlans[msg.sender][_dcaPlanID].executorsFeeAmount += msg.value;
        emit DCAPlanFeeIncreased(_dcaPlanID, msg.sender, msg.value);
    }

    function decreaseDCAPlanFee(
        uint256 _dcaPlanID,
        uint256 _decreaseAmount
    ) external notPaused {
        /*
            Allow user to decrease the total amount of fee stoked in the DCA
        */
        DCAPlan[] memory _dcaPlan = usersDCAPlans[msg.sender];
        require(_dcaPlan.length > _dcaPlanID, "Error: This DCA does not exist");
        require(
            _dcaPlan[_dcaPlanID].executorsFeeAmount >= _decreaseAmount,
            "Error: Decrease amount is higher than current fee"
        );
        require(
            _decreaseAmount > 0,
            "Error: Fee decrease must be higher than 0"
        );
        require(
            _dcaPlan[_dcaPlanID].currentOccurrence <
                _dcaPlan[_dcaPlanID].totalOccurrences,
            "Error: DCA is already finished"
        );
        usersDCAPlans[msg.sender][_dcaPlanID]
            .executorsFeeAmount -= _decreaseAmount;
        emit DCAPlanFeeDecreased(_dcaPlanID, msg.sender, _decreaseAmount);
        (bool success, ) = msg.sender.call{value: _decreaseAmount}("");
        require(
            success,
            "Native Token Transfer failed while decreasing DCA fee"
        );
    }

    function modifyDCAPlanSlippageTolerance(
        uint256 _dcaPlanID,
        uint256 _newSlippage
    ) external notPaused {
        /*
            Allow user to change the slippage tolerance for its DCA
        */
        DCAPlan[] memory _dcaPlan = usersDCAPlans[msg.sender];
        require(_dcaPlan.length > _dcaPlanID, "Error: This DCA does not exist");
        require(
            _newSlippage < 100_000,
            "Error: Slippage tolerance must be inferior than 100%, with 5 decimals"
        );
        emit DCAPlanSlippageTolerancegeUpdated(
            _dcaPlanID,
            msg.sender,
            usersDCAPlans[msg.sender][_dcaPlanID].slippageTolerance5Decimals,
            _newSlippage
        );
        usersDCAPlans[msg.sender][_dcaPlanID]
            .slippageTolerance5Decimals = _newSlippage;
    }

    function getAllUserDCAPlans(
        address _userAddress
    ) external view returns (DCAPlan[] memory) {
        return usersDCAPlans[_userAddress];
    }

    // Need a separate function to get a specific DCA plan because of the way Solidity handles arrays
    function getUserDCAPlan(
        address _userAddress,
        uint256 _dcaPlanID
    ) external view returns (DCAPlan memory) {
        require(
            usersDCAPlans[_userAddress].length > _dcaPlanID,
            "Error: This DCA does not exist"
        );
        return usersDCAPlans[_userAddress][_dcaPlanID];
    }

    function getUserNumberOfDCAPlans(
        address _userAddress
    ) external view returns (uint256) {
        return usersDCAPlans[_userAddress].length;
    }

    function getAllPendingDCAPlans()
        external
        view
        returns (DCAPlan[] memory, address[] memory, uint256[] memory)
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 numberOfOccurrencesToExecute = 0;

        // First, count the number of plans that need to be executed for all users
        for (uint256 i = 0; i < usersAddresses.length; i++) {
            address userAddress = usersAddresses[i];
            for (uint256 j = 0; j < usersDCAPlans[userAddress].length; j++) {
                DCAPlan memory userDCA = usersDCAPlans[userAddress][j];
                uint256 nextExecutionTime = userDCA.creationTimestamp +
                    userDCA.periodDays *
                    1 days *
                    (userDCA.currentOccurrence);

                if (
                    currentTimestamp >= nextExecutionTime &&
                    userDCA.currentOccurrence < userDCA.totalOccurrences
                ) {
                    numberOfOccurrencesToExecute++;
                }
            }
        }

        // Allocate memory for the array of pending plans
        DCAPlan[] memory pendingOccurrencesToExecute = new DCAPlan[](
            numberOfOccurrencesToExecute
        );
        uint256[] memory dcaPlanIDs = new uint256[](
            numberOfOccurrencesToExecute
        );
        address[] memory dcaPlanUsers = new address[](
            numberOfOccurrencesToExecute
        );
        uint256 pendingIndex = 0;

        // Add each pending plan to the array for all users
        for (uint256 i = 0; i < usersAddresses.length; i++) {
            address userAddress = usersAddresses[i];
            for (uint256 j = 0; j < usersDCAPlans[userAddress].length; j++) {
                DCAPlan memory userDCA = usersDCAPlans[userAddress][j];
                uint256 nextExecutionTime = userDCA.creationTimestamp +
                    userDCA.periodDays *
                    1 days *
                    (userDCA.currentOccurrence);

                if (
                    currentTimestamp >= nextExecutionTime &&
                    userDCA.currentOccurrence < userDCA.totalOccurrences
                ) {
                    pendingOccurrencesToExecute[pendingIndex] = userDCA;
                    dcaPlanIDs[pendingIndex] = j;
                    dcaPlanUsers[pendingIndex] = userAddress;
                    pendingIndex++;
                }
            }
        }

        return (pendingOccurrencesToExecute, dcaPlanUsers, dcaPlanIDs);
    }

    //Functions to get/set contract global variables

    function pause() external onlyOwner {
        isPaused = true;
    }

    function unPause() external onlyOwner {
        isPaused = false;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "Error: New owner cannot be 0 address"
        );
        address oldOwner = owner;
        owner = _newOwner;
        emit NewOwner(oldOwner, _newOwner);
    }

    function setOwnerFee(uint256 _newOwnerFee) external onlyOwner {
        require(
            _newOwnerFee <= 1_000,
            "Error: Owner fee must be inferior than 1%, with 5 decimals"
        );
        uint256 oldOwnerFee = ownerFee5Decimals;
        ownerFee5Decimals = _newOwnerFee;
        emit OwnerFeeUpdated(oldOwnerFee, _newOwnerFee);
    }

    function setAchievementRouter(
        address _newAchievementRouter
    ) external onlyOwner {
        require(
            _newAchievementRouter != address(0),
            "Error: New achievement router cannot be 0 address"
        );
        address oldAchievementRouter = achievementRouterAddress;
        achievementRouterAddress = _newAchievementRouter;
        emit AchievementRouterUpdated(
            oldAchievementRouter,
            _newAchievementRouter
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct DCAPlan {
    uint256 periodDays;
    uint256 totalOccurrences;
    uint256 currentOccurrence;
    uint256 amountPerOccurrence;
    address tokenIn;
    address tokenOut;
    uint256 tokenInLockedAmount;
    address[] swapPath;
    uint256 executorsFeeAmount;
    address exchangeRouterAddress;
    uint256 slippageTolerance5Decimals;
    uint256 creationTimestamp;
    uint256[2][] occurrencesExchangePrices;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct TokenAchievements {
    uint256 creationFeeReduction;
}