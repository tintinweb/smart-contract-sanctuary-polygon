/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// 単純にオープンソースかどうか等、ライセンスを記述する。書かないとworningが出るらしい。
//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
// コンパイラのバージョン指定。指定されたバージョン以外のコンパイラではコンパイルされない。
// 下記は「0.8.9以上、0.9未満のコンパイラのみ許容する」という意味。
pragma solidity ^0.8.9;


// This is the main building block for smart contracts.
// ここからがスマコンの本体。classみたいなもの。(claas + interface)/2 みたいな感じらしい？
contract Token {
    // Some string type variables to identify the token.
	// トークン名
    string public name = "My Hardhat Token";
	// 識別子
    string public symbol = "MHT";

    // The fixed amount of tokens, stored in an unsigned integer type variable.
	// トークンの量を符号なしint型(256bit)で格納
    uint256 public totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
	// address型はアカウントのアドレス(ポインタみたいなもの)を格納する。
	// 今回はこのコントラクトのオーナー(作成者)のアドレスを格納
    address public owner;

    // A mapping is a key/value map. Here we store each account's balance.
	// mappingはkeyとvalueを紐づけたmap。keyはhash化される
	// 今回は各アカウントのアドレスと残高を保存
    mapping(address => uint256) balances;

    // The Transfer event helps off-chain applications understand
    // what happens within your contract.
	// eventはTransfer関数で何が起きているのか把握できる
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * Contract initialization.
     */
	// コンストラクタ　コントラクト作成時一度だけ呼ばれる
    constructor() {
        // The totalSupply is assigned to the transaction sender, which is the
        // account that is deploying the contract.
		// トランザクション送信者であるコントラクトをデプロイしたアカウントにtotalSupplyを割り当てる
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from *outside*
     * the contract.
     */
	// externalでコントラクトの外からのみ呼び出せるようにできる
    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;

        // Notify off-chain applications of the transfer.
        emit Transfer(msg.sender, to, amount);
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}