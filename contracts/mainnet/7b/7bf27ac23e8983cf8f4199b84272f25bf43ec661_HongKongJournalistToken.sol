/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

pragma solidity ^0.8.16;

contract HongKongJournalistToken {
    string public constant name = "Hong Kong Journalist Token";
    string public constant symbol = "HKJ";
    uint8 public constant decimals = 6;
    uint256 private constant multiplier = 1000000;

    // Total circulating supply
    uint256 private _totalSupply;

    // One "claim" call gives the sender (1 << _epoch) Tank Coins
    uint256 private _epoch;

    // After 8 rounds, rewards are halved
    uint256 private _round;

    // Total supply of Tank Coins that have been burnt
    uint256 private _totalBurned;

    // Total locked Tank Coins that will slowly be unlocked
    uint256 private _totalLocked;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
 
    constructor(uint256 total) public {
        // Prevent: not enough tokens to claim / overflow
        require(total >= 7 && total <= 228);
        _totalSupply = (1 << total) * multiplier;

        uint256 poolAmount = (1 << (total - 2)) * multiplier;
        uint256 claimableAmount = (1 << (total - 3)) * multiplier;

        // Initialize balances
        balances[msg.sender] = _totalSupply - poolAmount - claimableAmount;

        // 1/8 is temporarily locked at null address
        // For anyone who is willing to claim the token.
        balances[address(0x0)] = claimableAmount;

        // 1/4 is temporarily locked at 0x00000...01
        // Used as a pool of reward, including transaction rewards and lottery rewards.
        balances[address(0x01)] = poolAmount;
        _totalLocked = poolAmount;

        // In the 1st epoch, we distribute (1 / 8) / 8 of the total supply to "claim" sender
        _epoch = total - 7;
        require(_epoch >= 0);

        // _round was initially 0.
        // After 8 rounds, rewards are halved.
        _round = 0;
        _totalBurned = 0;
    }

	function add(uint256 x, uint256 y) private pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) private pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function max(uint256 x, uint256 y) private pure returns (uint256 z) {
        return x > y ? x : y;
    }

    function min(uint256 x, uint256 y) private pure returns (uint256 z) {
        return x < y ? x : y;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transferInternal(address from, address to, uint256 amount) private returns (bool success) {
        require(balances[from] >= amount);
        balances[from] = sub(balances[from], amount);
        balances[to] = add(balances[to], amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function giveTransferReward(address to, uint256 amount) private returns (bool success) {
        // For each transfer, we give 0.0005% of the locked amount, or 5% the transferred amount, whichever is smaller, to the sender as a reward.
        uint256 transferReward = min(balances[address(0x01)] / 200000, amount / 20);
        if (transferReward > 0) {
            transferInternal(address(0x01), to, transferReward);
            _totalLocked = sub(_totalLocked, transferReward);
        }
        return (transferReward > 0);
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        if (to == address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)) {
            return burn(tokens);
        }

        transferInternal(msg.sender, to, tokens);

        // For each transfer, we give 0.0005% of the locked amount to the sender as a reward
        giveTransferReward(msg.sender, tokens);

        return true;
    }
    
    function bulkTransfer(address[] calldata tokenOwners, uint256[] calldata tokens) public returns (bool success) {
        require(tokenOwners.length == tokens.length);
        uint256 transferred = 0;
        for (uint i = 0; i < tokenOwners.length; i++) {
            if (tokenOwners[i] == address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)) {
                burn(tokens[i]);
            } else {
                transferred += tokens[i];
                transferInternal(msg.sender, tokenOwners[i], tokens[i]);
            }
        }
        // For each transfer, we give 0.0005% of the locked amount to the sender as a reward
        giveTransferReward(msg.sender, transferred);
        return true;
    }

    function bulkTransferFixedAmount(address[] calldata tokenOwners, uint256 tokens) public returns (bool success) {
        require(tokenOwners.length > 0);
        uint256 transferred = 0;
        for (uint i = 0; i < tokenOwners.length; i++) {
            if (tokenOwners[i] == address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)) {
                burn(tokens);
            } else {
                transferred += tokens;
                transferInternal(msg.sender, tokenOwners[i], tokens);
            }
        }

        // For each transfer, we give 0.0005% of the locked amount to the sender as a reward
        giveTransferReward(msg.sender, transferred);
        
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        transferInternal(from, to, tokens);

        if (to == address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)) {
            _totalBurned = add(_totalBurned, tokens);
        }

        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function claim() public returns (bool success) {
        return claimFor(msg.sender);
    }

    function claimFor(address to) public returns (bool success) {
        // If all was claimed...
        if (_epoch < 0) {
            // At least has 1 token?
            uint256 c = min(multiplier, balances[address(0x0)]);
            require(c > 0);
            transferInternal(address(0x0), to, c);
            return true;
        }

        // Require that the null address has enough balance to claim
        uint256 toClaim = (1 << _epoch) * multiplier;
        require(balances[address(0x0)] >= toClaim);

        // Give the sender the reward
        transferInternal(address(0x0), to, toClaim);
        
        // Increment the round
        _round = add(_round, 1);

        // If the round is 8, halve the rewards
        if (_round >= 8) {
            _round = 0;
            _epoch = sub(_epoch, 1);
        }
        return true;
    }

    function currentReward() public view returns (uint256 reward) {
        return (1 << _epoch);
    }

    function burn(uint256 tokens) public returns (bool success) {
        // Burnt tokens are transferred to 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
        transferInternal(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), tokens);
        _totalBurned = add(_totalBurned, tokens);
        return true;
    }

    function totalBurned() public view returns (uint256 total) {
        return _totalBurned;
    }

    function totalLocked() public view returns (uint256 total) {
        return balances[address(0x01)];
    }

    function lottery(uint256 amount) public returns (bool win) {
        // Check for sufficient balance
        require(balances[msg.sender] >= amount && amount > 0 && (amount / 2000 * 198) <= balances[address(0x01)]);

        // Get previous block hash
        bytes32 blockHash = blockhash(block.number - 1);

        // Get the MSB of amount
        uint256 msb = amount;
        while (msb >= 10) {
            msb = msb / 10;
        }
        require(msb >= 1 && msb <= 9);

        // Transferring the bet to the pool
        transferInternal(msg.sender, address(0x01), amount);
        _totalLocked = add(_totalLocked, amount);

        uint256 winningNumber = uint8(blockHash[31]);
        if ((msb % 2) == (winningNumber % 2)) {
            uint256 winAmount = (amount / 100) * 198;
            transferInternal(address(0x01), msg.sender, winAmount);
            _totalLocked = sub(_totalLocked, winAmount);
            win = true;
        }
    }
}