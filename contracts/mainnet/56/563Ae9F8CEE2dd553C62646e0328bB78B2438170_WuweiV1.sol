/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

pragma solidity ^0.8.0;

//@crzypatchwork @hicetnunc2000 GPL-3.0
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@   @@@  &@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@                    @@@@,%&&&&&&&  &&&&&&%*@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@.  @  @@@  @@@ /@@@ @@@@@@@@@@@@@@@  @@@@@@/ &@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@                        @@@@@@@@@/             @@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@  @@@  @@@ /@@@ @@@@@@@@@@@@  @@@@@@@@@@@  @@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@  @@@  @@@ /@@@ @@@@@@@@@@                   %@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@                       @@@   @@@@@@@@@/@@  @@@  @@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@  @@@  @@@  @@@@  ,@@@@@@@@  @@@ @@@  @@/ @@  @@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@  @@@@  @@@@  @@@@@  @@@@@@  @@@@  @@% @@@@@  #@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@ %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

interface ERC1155Interface {
    
    function safeTransferFrom(        
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external;

    function royaltyInfo(
        uint256,
        uint256
    ) external returns (address, uint256);

    function supportsInterface(
        bytes4
    ) external returns (bool);
            
}

interface ERC20Interface {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

struct SwapStructV1 {
    
    address erc1155;
    address issuer; // swap issuer as msg.sender
    uint256 amount;
    uint256 value;
    uint256 tokenId;
    bool active;
    
}

struct SwapStructV2 {

    address erc20;
    address issuer;
    uint256 amount;
    uint256 value;
    bool active;

}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/security/ReentrancyGuard.sol

contract ReEntrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;

        _status = _NOT_ENTERED;
    }
}

contract WuweiV1 is ReEntrancyGuard {

    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    event swapLog(address erc1155, uint256 amount, uint256 value, uint256 tokenId, uint256 op, uint256 indexed swapId);

    uint256 public nonce;
    uint256 public fee;
    address public manager;
    mapping(uint256 => SwapStructV1) public swaps;

    constructor(address _manager, uint256 _fee) public { manager = _manager; fee = _fee; }
    
    // management
    
    function updateFee(uint256 _fee) public { require(msg.sender == manager); fee = _fee; }
    
    function updateManager(address _manager) public { require(msg.sender == manager); manager = _manager; }
    
    // erc1155 approval must be given
    
    function swap(uint256 _id, uint256 _amount, uint256 _value, address _erc1155) public nonReentrant {
        
        require(((_value == 0) || (_value >= 10000)) && ((_amount > 0) && (_amount <= 10000)));

        nonce++;

        // mapping
        swaps[nonce] = SwapStructV1(_erc1155, msg.sender, _amount, _value, _id, true);

        // transfer erc1155 to escrow
        ERC1155Interface(_erc1155).safeTransferFrom(msg.sender, address(this), _id, _amount, '0x00');

        // event
        emit swapLog(_erc1155, _amount, _value, _id, 0, nonce);

    }
    
    function cancelSwap(uint256 _swapId) public nonReentrant {
        require((swaps[_swapId].issuer == msg.sender) && (swaps[_swapId].active));
        
        // mapping
        swaps[_swapId].active = false;
        uint256 _amount = swaps[_swapId].amount;

        swaps[_swapId].amount = 0;
        swaps[_swapId].value = 0;
        
        // transfer erc1155 out of escrow
        ERC1155Interface(swaps[_swapId].erc1155).safeTransferFrom(address(this), msg.sender, swaps[_swapId].tokenId, _amount, '0x00');
        
        // event
        emit swapLog(swaps[_swapId].erc1155, _amount, 0, swaps[_swapId].tokenId, 2, _swapId);
    }
    
    function collect(uint256 _swapId, uint256 _amount) public payable nonReentrant {
        
        require(
            (swaps[_swapId].amount > 0) && 
            ((msg.value == 0) || (msg.value >= 10000)) &&
            (swaps[_swapId].active) &&
            (msg.sender != swaps[_swapId].issuer) &&
            (_amount <= swaps[_swapId].amount) &&
            (msg.value == swaps[_swapId].value * _amount)
            );

        // storage changes/retrancy measures

        swaps[_swapId].amount -= _amount;

        if (swaps[_swapId].amount == 0) swaps[_swapId].active = false;

        uint256 auxFee = ((fee * msg.value) / 10000);

        if (msg.value != 0) {
            
            if (ERC1155Interface(swaps[_swapId].erc1155).supportsInterface(_INTERFACE_ID_ROYALTIES_EIP2981)) {

                // EIP2981

                (address creator, uint256 royalties) = ERC1155Interface(swaps[_swapId].erc1155).royaltyInfo(swaps[_swapId].tokenId, msg.value);

                // royalties, management fees and market value distribution
                if (fee != 0) manager.call{ value : auxFee }("");    
                creator.call{ value : royalties }("");
                swaps[_swapId].issuer.call{ value : msg.value - (royalties + auxFee) }("");

            } else {

                if (fee != 0) manager.call{ value : auxFee }("");
                swaps[_swapId].issuer.call{ value : msg.value - auxFee }("");

            }

        }
        
        // transfer erc1155
        ERC1155Interface(swaps[_swapId].erc1155).safeTransferFrom(address(this), msg.sender, swaps[_swapId].tokenId, _amount, '0x00');
        
        emit swapLog(swaps[_swapId].erc1155, _amount, swaps[_swapId].value * _amount, swaps[_swapId].tokenId, 1, _swapId);

    }
    
}