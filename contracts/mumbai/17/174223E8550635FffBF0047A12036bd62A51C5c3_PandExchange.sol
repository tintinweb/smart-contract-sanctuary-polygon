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

import "./Interfaces/IRouter02.sol";
import "./Interfaces/IERC20.sol";

//Data structure to store the user's DCA data
struct UserDCAData {
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
}

contract PandExchange {
    /*
        PandExchange is a contract that allows you to exchange your tokens for another token using the DCA method.
        You can create a DCA Operation by calling the createDCAOperation function.
        You can cancel a DCA Operation by calling the cancelDCAOperation function.
        You can execute a DCA Operation by calling the executeDCAOperation function.
        As you cannot schedule functions executions in contracts, you have to call the executeDCAOperation function manually.
        To reward the users who call the executeDCAOperation function, a fee put during the DCA creation and is then redistributed to the caller, to compensate the gas fees.
        By doing so, this DApp can remain fully decentralized and trustless.
        There is a 0.5% fee of the amount of tokens to be exchanged, given to the contract owner to support the application development.
        All token swap are done using the DEX Router chosen by the user, at the DCA creation.
    */
    address public owner;
    bool public isPaused;

    mapping(address => UserDCAData[]) public mapDCA;
    mapping(address => bool) public hasAnActiveDCA;
    address[] public usersAddresses;

    uint256 public ownerFee5Decimals; //5 decimals (ie 0.5% = 500), maximum 1% fee

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

    event AddedNewDCA(
        uint256 indexed dcaID,
        address indexed userAddress,
        uint256 creationTimestamp,
        uint256 totalOccurrence,
        uint256 period
    );
    event OccurrenceExecuted(
        uint256 indexed dcaID,
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
    event DeletedDCA(uint256 indexed dcaID, address indexed userAddress);
    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event DCAFeeIncreased(
        uint256 indexed dcaID,
        address indexed userAddress,
        uint256 increaseAmount
    );
    event DCAFeeDecreased(
        uint256 indexed dcaID,
        address indexed userAddress,
        uint256 decreaseAmount
    );
    event SlippageTolerancegeUpdated(
        uint256 indexed dcaID,
        address indexed userAddress,
        uint256 oldSlippageTolerance,
        uint256 newSlippageTolerance
    );
    event OwnerFeeUpdated(uint256 oldOwnerFee, uint256 newOwnerFee);

    function addNewDCAToUser(
        UserDCAData memory _userDCAData,
        uint256 _amountOutMinFirstTransaction
    ) external payable notPaused returns (uint256) {
        //Add a DCA to the calling user and take the necessary funds to the contract
        //The funds can be retrieved at all time be cancelling the DCA
        //If one of the two address is address(0), its the chain native token

        uint256 timestamp = block.timestamp;
        uint256 totalAmountOverall = _userDCAData.totalOccurrences *
            _userDCAData.amountPerOccurrence;

        require(
            _userDCAData.periodDays *
                _userDCAData.totalOccurrences *
                _userDCAData.amountPerOccurrence >
                0,
            "Error: DCA Period, Total Occurrences and Amount Per Occurrence must be all greater than 0"
        );
        require(
            _userDCAData.slippageTolerance5Decimals < 100_000,
            "Error: Slippage tolerance must be inferior than 1, with 5 decimals"
        );
        require(
            _userDCAData.currentOccurrence == 0,
            "Error: Current occurrence must be 0 at the start"
        );
        require(
            _userDCAData.tokenIn != _userDCAData.tokenOut,
            "Error: Token In and Token Out must be different"
        );
        if (_userDCAData.tokenIn == address(0)) {
            address WETH = IRouter02(_userDCAData.exchangeRouterAddress)
                .WETH();
            require(_userDCAData.swapPath[0] == WETH, "Error: Wrong path");
        } else if (_userDCAData.tokenOut == address(0)) {
            address WETH = IRouter02(_userDCAData.exchangeRouterAddress)
                .WETH();
            require(
                _userDCAData.swapPath[_userDCAData.swapPath.length - 1] == WETH,
                "Error: Wrong path"
            );
        } else {
            require(
                _userDCAData.swapPath[0] == _userDCAData.tokenIn,
                "Error: Wrong path"
            );
            require(
                _userDCAData.swapPath[_userDCAData.swapPath.length - 1] ==
                    _userDCAData.tokenOut,
                "Error: Wrong path"
            );
        }

        if (!hasAnActiveDCA[msg.sender]) {
            usersAddresses.push(msg.sender);
            hasAnActiveDCA[msg.sender] = true;
        }

        uint256 ownerFee = ((totalAmountOverall * 100_000) *
            ownerFee5Decimals) / 10_000_000_000;

        _userDCAData.tokenInLockedAmount = totalAmountOverall - ownerFee;
        _userDCAData.creationTimestamp = timestamp;
        _userDCAData.amountPerOccurrence =
            _userDCAData.tokenInLockedAmount /
            _userDCAData.totalOccurrences;

        mapDCA[msg.sender].push(_userDCAData);

        emit AddedNewDCA(
            mapDCA[msg.sender].length - 1,
            msg.sender,
            timestamp,
            _userDCAData.totalOccurrences,
            _userDCAData.periodDays
        );
        if (_userDCAData.tokenIn != address(0)) {
            //Require the user to approve the transfer beforehand
            bool success = IERC20(_userDCAData.tokenIn).transferFrom(
                msg.sender,
                address(this),
                totalAmountOverall
            );
            require(success, "Error: TokenIn TransferFrom failed");
            require(
                msg.value == _userDCAData.executorsFeeAmount,
                "Error: Wrong amount of Native Token sent for the fee"
            );
        } else {
            require(
                msg.value ==
                    totalAmountOverall + _userDCAData.executorsFeeAmount,
                "Error: Wrong amount of Native Token sent"
            );
        }

        //The first occurrence is executed immediately
        executeSingleUserDCA(
            msg.sender,
            mapDCA[msg.sender].length - 1,
            _amountOutMinFirstTransaction
        );
        //Send the owner fee, a one time fee at the creation of the DCA
        sendFee(owner, _userDCAData.tokenIn, ownerFee);

        return timestamp;
    }

    function deleteUserDCA(uint256 dcaID) external {
        /*Delete a DCA to free the storage and transfer back to the user the remaining amount of token IN
            address(0) as the IN our OUT token mean that it is Native Token
        */
        UserDCAData[] memory userDCAData = mapDCA[msg.sender];
        require(
            userDCAData.length > dcaID,
            "Error: No DCA with this ID for this user"
        );

        //Delete the DCA from the array
        mapDCA[msg.sender][dcaID] = userDCAData[userDCAData.length - 1];
        mapDCA[msg.sender].pop();

        emit DeletedDCA(dcaID, msg.sender);

        bool tokenInTransfer = false;
        if (userDCAData[dcaID].tokenIn != address(0)) {
            tokenInTransfer = IERC20(userDCAData[dcaID].tokenIn).transfer(
                msg.sender,
                userDCAData[dcaID].tokenInLockedAmount
            );
            require(
                tokenInTransfer,
                "ERC20 Transfer failed while deleting DCA."
            );
        } else {
            (tokenInTransfer, ) = msg.sender.call{
                value: userDCAData[dcaID].tokenInLockedAmount
            }("");
            require(
                tokenInTransfer,
                "Native token Transfer failed while deleting DCA."
            );
        }

        bool feeTransfer = false;
        (feeTransfer, ) = msg.sender.call{
            value: userDCAData[dcaID].executorsFeeAmount
        }("");
        require(feeTransfer, "Fee Transfer failed while deleting DCA.");
    }

    function executeSingleUserDCA(
        address _userAddress,
        uint256 _dcaID,
        uint256 _amountOutMin
    ) public notPaused {
        /*  Execute a single occurrence of a single DCA for the user
            Find the right one by the user address and startDate value, which is unique for each DCA of a specific user
            It implies that we must know this exact value, which is done by listening to the AddedNewDCA event
            A contract that created a DCA can also get this as a return value of the addNewDCAToUser() function
            This function reward the caller with a percentage of the input token traded in an occurrence, to compensate for the gas fees
            Steps :
             - Security checks
               - The DCA must exist
               - The current date must be around startDate + period * currentOccurrence 
               - The currentOccurrence number should be lower than the totalOccurrence (i.e. not completed)
             - Modify the userDCAData state to reflect the operation (need to do it 1st to avoid re-entrency attacks)
                - Increment the number of occurrence
                - Modify the lockedAmount of each token
             - Swap the defined amount of tokens, minus the fee, with the swap() function 
             - Send the fee to the caller of the function
             - Send the fee to the address that executed this function
             TODO: 
        */
        UserDCAData[] memory userDCAData = mapDCA[_userAddress];
        require(
            userDCAData.length > _dcaID,
            "Error: No DCA with this ID for this user"
        );
        UserDCAData memory userDCA = userDCAData[_dcaID];
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

        mapDCA[_userAddress][_dcaID].currentOccurrence =
            userDCA.currentOccurrence +
            1;

        bool isLastOccurrence = userDCA.totalOccurrences ==
            userDCA.currentOccurrence + 1;

        uint256 tradeAmount = userDCA.amountPerOccurrence;

        if (isLastOccurrence) {
            tradeAmount = userDCA.tokenInLockedAmount;
            mapDCA[_userAddress][_dcaID].tokenInLockedAmount = 0;
        } else {
            mapDCA[_userAddress][_dcaID].tokenInLockedAmount =
                userDCA.tokenInLockedAmount -
                userDCA.amountPerOccurrence;
        }

        uint256 feeCaller = 0;
        //If the caller is not the user, he will get a fee to compensate for the gas fees
        //The fee is set by the user when he created the DCA
        if (msg.sender != _userAddress) {
            feeCaller =
                userDCA.executorsFeeAmount /
                (userDCA.totalOccurrences - userDCA.currentOccurrence);
        }
        mapDCA[_userAddress][_dcaID].executorsFeeAmount -= feeCaller;

        //Set the timestamp of the next occurrence. 0 if it is the last one (i.e. currentOccurrence == totalOccurrences)
        uint256 nextOccurrenceTimestamp = 0;
        if (userDCA.totalOccurrences > userDCA.currentOccurrence + 1) {
            nextOccurrenceTimestamp =
                _dcaID +
                (userDCA.currentOccurrence + 1) *
                userDCA.periodDays *
                1 days;
        }
        emit OccurrenceExecuted(
            _dcaID,
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
        else if (_tokenOut == address(0)) {
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

    function increaseDCAFee(uint256 _dcaID) external payable notPaused {
        /*
            Allow user to increase the total amount of fee stoked in the DCA
        */
        UserDCAData[] memory userDCAData = mapDCA[msg.sender];
        require(
            userDCAData.length > _dcaID,
            "Error: This DCA does not exist"
        );
        require(msg.value > 0, "Error: Fee amount must be higher than 0");
        require(
            userDCAData[_dcaID].currentOccurrence <
                userDCAData[_dcaID].totalOccurrences,
            "Error: DCA is already finished"
        );
        mapDCA[msg.sender][_dcaID].executorsFeeAmount += msg.value;
        emit DCAFeeIncreased(_dcaID, msg.sender, msg.value);
    }

    function decreaseDCAFee(
        uint256 _dcaID,
        uint256 _decreaseAmount
    ) external notPaused {
        /*
            Allow user to decrease the total amount of fee stoked in the DCA
        */
        UserDCAData[] memory userDCAData = mapDCA[msg.sender];
        require(
            userDCAData.length > _dcaID,
            "Error: This DCA does not exist"
        );
        require(
            userDCAData[_dcaID].executorsFeeAmount >= _decreaseAmount,
            "Error: Decrease amount is higher than current fee"
        );
        require(
            _decreaseAmount > 0,
            "Error: Fee decrease must be higher than 0"
        );
        require(
            userDCAData[_dcaID].currentOccurrence <
                userDCAData[_dcaID].totalOccurrences,
            "Error: DCA is already finished"
        );
        mapDCA[msg.sender][_dcaID].executorsFeeAmount -= _decreaseAmount;
        emit DCAFeeDecreased(_dcaID, msg.sender, _decreaseAmount);
        (bool success, ) = msg.sender.call{value: _decreaseAmount}("");
        require(
            success,
            "Native Token Transfer failed while decreasing DCA fee"
        );
        
    }

    function modifySlippageTolerance(
        uint256 _dcaID,
        uint256 _newSlippage
    ) external notPaused {
        /*
            Allow user to change the slippage tolerance for its DCA
        */
        UserDCAData[] memory userDCAData = mapDCA[msg.sender];
        require(
            userDCAData.length > _dcaID,
            "Error: This DCA does not exist"
        );
        require(
            _newSlippage < 100_000,
            "Error: Slippage tolerance must be inferior than 100%, with 5 decimals"
        );
        emit SlippageTolerancegeUpdated(
            _dcaID,
            msg.sender,
            mapDCA[msg.sender][_dcaID].slippageTolerance5Decimals,
            _newSlippage
        );
        mapDCA[msg.sender][_dcaID].slippageTolerance5Decimals = _newSlippage;
    }

    function getUserNumberOfDCAs(
        address _userAddress
    ) external view returns (uint256) {
        return mapDCA[_userAddress].length;
    }

    function getAllPendingDCAPlans() external view returns (UserDCAData[] memory) {
    uint256 currentTimestamp = block.timestamp;
    uint256 numberOfOccurrencesToExecute = 0;

    // First, count the number of plans that need to be executed for all users
    for (uint256 i = 0; i < usersAddresses.length; i++) {
        address userAddress = usersAddresses[i];
        for (uint256 j = 0; j < mapDCA[userAddress].length; j++) {
            UserDCAData memory userDCA = mapDCA[userAddress][j];
            uint256 nextExecutionTime = userDCA.creationTimestamp + userDCA.periodDays * 1 days * (userDCA.currentOccurrence);

            if (currentTimestamp >= nextExecutionTime && userDCA.currentOccurrence < userDCA.totalOccurrences) {
                numberOfOccurrencesToExecute++;
            }
        }
    }

    // Allocate memory for the array of pending plans
    UserDCAData[] memory pendingOccurrencesToExecute = new UserDCAData[](numberOfOccurrencesToExecute);
    uint256 pendingIndex = 0;

    // Add each pending plan to the array for all users
    for (uint256 i = 0; i < usersAddresses.length; i++) {
        address userAddress = usersAddresses[i];
        for (uint256 j = 0; j < mapDCA[userAddress].length; j++) {
            UserDCAData memory userDCA = mapDCA[userAddress][j];
            uint256 nextExecutionTime = userDCA.creationTimestamp + userDCA.periodDays * 1 days * (userDCA.currentOccurrence);

            if (currentTimestamp >= nextExecutionTime && userDCA.currentOccurrence < userDCA.totalOccurrences) {
                pendingOccurrencesToExecute[pendingIndex] = userDCA;
                pendingIndex++;
            }
        }
    }

    return pendingOccurrencesToExecute;
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
}