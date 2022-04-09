pragma solidity >=0.8.0;
import "./IRandomGenerator.sol";

contract UpDown {
    /// *** Constants section

    // Each bet is deducted 1.5% in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing
    // headroom for up to 10 Gwei prices.
    uint256 constant HOUSE_EDGE_THOUSANDTHS = 15;
    uint256 constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;
    // Fix bets' size.
    uint256 constant BET_SIZE1 = 5 * 10**15;
    uint256 constant BET_SIZE2 = 10 * 10**6;
    uint256 constant BET_SIZE3 = 50 * 10**6;
    uint256 constant BET_SIZE4 = 100 * 10**6;
    uint256 constant BET_SIZE5 = 500 * 10**6;
    uint256 constant BET_SIZE6 = 1000 * 10**6;
    uint256 constant BET_SIZE7 = 5000 * 10**6;
    uint256 constant BET_SIZE8 = 10000 * 10**6;

    uint256 constant MAX_MODULO = 100;
    uint256 constant MAX_MASK_MODULO = 40;
    uint256 constant MAX_BET_MASK = 2**MAX_MASK_MODULO;
    uint256 constant BET_EXPIRATION_BLOCKS = 250;
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IRandomGenerator randomGenerator = IRandomGenerator(0xe5e59A851406A2B61B4C3142c89F3E12623340E1);
    uint256 public randomRoundId;
    // Standard contract ownership transfer.
    address payable public owner;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed beneficiary, uint256 amount);
    event Payment(address indexed beneficiary, uint256 amount);
    event ReferralPayment(address indexed beneficiary, uint256 amount);
    event Number(uint8 number);

    // Constructor. Deliberately does not take any parameters.
    constructor() public {
        owner = payable(msg.sender);
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    function changeOwner(address payable _owner) external onlyOwner() {
        owner = _owner;
    }

    receive() external payable {}


    // Funds withdrawal to cover costs of dice2.win operation.
    function withdrawFunds(
        address payable beneficiary, 
        uint256 withdrawAmount
        )
        external
        onlyOwner()
    {
        require(
            withdrawAmount <= address(this).balance,
            "amount larger than balance."
        );
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }


    // Bet placing transaction - issued by the player.
    //  betMask         - bet outcomes bit mask for modulo <= MAX_MASK_MODULO,
    //                    [0, betMask) for larger modulos.
    //  modulo          - game modulo.
    function placeBet(
        uint256 betMask
    ) external payable {

        // Validate input data ranges.
        uint256 amount = msg.value;
        require(
            amount == BET_SIZE1 ||
                amount == BET_SIZE2 ||
                amount == BET_SIZE3 ||
                amount == BET_SIZE4 ||
                amount == BET_SIZE5 ||
                amount == BET_SIZE6 ||
                amount == BET_SIZE7 ||
                amount == BET_SIZE8,
            "Amount should be within range."
        );
        require(
            betMask > 0 && betMask < MAX_BET_MASK && betMask < 101,
            "Mask should be within range."
        );
        require(msg.sender == tx.origin);

        (uint256 roundId, uint256 dice,) =
            randomGenerator.latestRoundData(101);
        
        require(
            roundId > randomRoundId, 
            "RoundId should be greater than randomRoundId"
            );

        randomRoundId = roundId;

        emit Number(dice);
        uint256 diceWinAmount = getDiceWinAmount(amount, 100, betMask);
        uint256 diceWin = 0;
        if (dice < betMask) {
            diceWin = diceWinAmount;
        }
        // Send the funds to gambler.
        sendFunds(payable(msg.sender), diceWin == 0 ? 0 wei : diceWin, diceWin);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(
        uint256 amount,
        uint256 modulo,
        uint256 rollUnder
    ) private pure returns (uint256 winAmount) {
        require(
            0 < rollUnder && rollUnder <= modulo,
            "Win probability out of range."
        );
        uint256 houseEdge = (amount * HOUSE_EDGE_THOUSANDTHS) / 1000;
        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
        require(houseEdge <= amount, "Bet doesn't even cover house edge.");
        winAmount = ((amount - houseEdge) * modulo) / rollUnder;
    }

    // Helper routine to process the payment.
    function sendFunds(
        address payable beneficiary,
        uint256 amount,
        uint256 successLogAmount
    ) private {
        if (amount > 0) {
            if (beneficiary.send(amount)) {
                emit Payment(beneficiary, successLogAmount);
            } else {
                emit FailedPayment(beneficiary, amount);
            }
        } else {
            emit Payment(beneficiary, 0);
        }
    }

    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint256 constant POPCNT_MULT =
        0x0000000000002000000000100000000008000000000400000000020000000001;
    uint256 constant POPCNT_MASK =
        0x0001041041041041041041041041041041041041041041041041041041041041;
    uint256 constant POPCNT_MODULO = 0x3F;

    event Number(uint256 n);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IRandomGenerator{
    
    function latestRoundData(uint256 modulus) external returns (uint256, uint256, uint256);
    
    function getSeed() external view returns(uint256);
    function setSeed(uint256 _seed) external; 
    function getCounter() external view returns(uint256);
    function addViewRole(address account) external;
    function removeFromViewRole(address account) external;
}