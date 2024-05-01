// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import "./libraries/SafeMath.sol";

contract LuckyCoin {
    using SafeMath for uint;
    //public keysword for state variables creates public getter but not setter
    string public constant name = "LuckyCoin";
    string public constant symbol = "LUCK";
    uint8 public constant decimals = 10; 
    uint public totalSupply;
    uint256 public transactionCount; // Amount of transactions since last draw
    uint256 public constant lotteryThreshold = 10; // Amount of transaction to trigger a draw
    uint256 public constant lotteryFee = 10; // 10% fee for every transaction
    uint256 private _nonce = 0;
    address private _lotteryTickets = new address[](lotteryThreshold);
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    //mapping(address => uint) public nonces; //?

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        _mint(msg.sender, 777 * 10 ** uint256(decimals));
    }
    //why are some internal and some private?
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        // Calculate fees paid by the user
        uint256 fee = amount / lotteryFee;

        // Transfer value without fee to receiver
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value - fee);

        // Fees are paid to 0x0
        balanceOf[address(0)] = balanceOf[address(0)].add(fee);

        // Add address to lottery tickets
        _lotteryTickets[transactionCount] = from;
        transactionCount++;

        // Draw from lottery if threshold has been reached
        if (transactionCount >= lotteryThreshold) {
            _drawLottery();
        }
        emit Transfer(from, to, value - fee);
        emit Transfer(from, address(0), fee);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function lotteryDraw() internal {
        // Determine "random" index using hash function
        _nonce++;
        uint i = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,_nonce))) % lotteryThreshold;

        // Transfer from pool to winner
        address winner = _lotteryTickets[i];
        uint256 value = balanceOf[address(0)];
        balanceOf[address(0)] = 0;
        balanceOf[winner] = balanceOf[to].add(value);

        // Reset counter
        transactionCount = 0;

        emit Transfer(address(0), to, value);
    }
    
}
