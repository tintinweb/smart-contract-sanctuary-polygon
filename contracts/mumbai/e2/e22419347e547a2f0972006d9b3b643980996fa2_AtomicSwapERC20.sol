/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract AtomicSwapERC20 {

    struct Swap{
        uint256 swapID;
        address erc20DT;
        address erc20WDT;
        uint256 amountDT;
        uint256 amountWDT;
        address initiator;
    }

    enum States {
        OPEN,
        CLOSED,
        REVOKED
    }

    mapping(uint256 => Swap) public swaps;
    mapping(uint256 => States) public swapStates;
    //Add a mapping to store who closed the trade. (H.W)
    mapping (uint => address) public userSwapClose;
    //Only the person with a particular address can come and close the trade. (HW)

    event OpenSwap(uint swapID, address erc20DT, address erc20WDT, uint amountDT, uint amountWDT);
    event CloseSwap(uint swapID, string message);
    event RevokeSwap(uint swapID, string message);

    function openSwap(uint256 _swapID, address _erc20DT, address _erc20WDT, uint256 _amountDT, uint256 _amountWDT) public {

        IERC20 erc20DT = IERC20(_erc20DT);
        require(erc20DT.allowance(msg.sender, address(this)) >= _amountDT);
        require(erc20DT.transferFrom(msg.sender, address(this), _amountDT));

        Swap memory swap = Swap({
            swapID: _swapID,
            erc20DT: _erc20DT,
            erc20WDT: _erc20WDT,
            amountDT: _amountDT,
            amountWDT: _amountWDT,
            initiator: msg.sender
        });

        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

        //Emit event for openswap. (HW)
        emit OpenSwap(_swapID, _erc20DT, _erc20WDT, _amountDT, _amountWDT);
    }



    function closeSwap(uint256 _swapID) public onlyOpenSwaps(_swapID) notInitiator(_swapID) {
        Swap memory swap = swaps[_swapID];

        IERC20 erc20DT = IERC20(swap.erc20DT);
        IERC20 erc20WDT = IERC20(swap.erc20WDT);

        require(swap.amountWDT <= erc20WDT.allowance(msg.sender, address(this)));

        require(erc20WDT.transferFrom(msg.sender, swap.initiator, swap.amountWDT));

        require(erc20DT.transfer(msg.sender, swap.amountDT));

        swapStates[_swapID] = States.CLOSED;

        // HW - mapping who closed the trade
        userSwapClose[_swapID] = msg.sender;

        //Emit event for closeSwap(HW)
        emit CloseSwap(_swapID, "Swap closed");
        // What is re-entrancy attack?

    }

    function revokeSwap(uint256 _swapID) public onlyOpenSwaps(_swapID) onlyInitiator(_swapID) {
        Swap memory swap = swaps[_swapID];
        swapStates[_swapID] = States.REVOKED;

        IERC20 erc20ContractDT = IERC20(swap.erc20DT);
        require(erc20ContractDT.transfer(swap.initiator, swap.amountDT));

        // Emit event for revoked swap!
        emit RevokeSwap(_swapID, "Swap revoked");
    }

    
    function checkSwap(uint _swapID) public view returns (Swap memory) {
        return swaps[_swapID];
    }




    modifier onlyOpenSwaps(uint256 _swapID) {
        require(swapStates[_swapID] == States.OPEN);
        _;
    }

    modifier onlyInitiator(uint256 _swapID) {
        require(msg.sender == swaps[_swapID].initiator, "You can not close the trade!");
        _;
    }

    modifier notInitiator(uint256 _swapID) {
        require(msg.sender != swaps[_swapID].initiator, "You can not close the trade!");
        _;
    }


}