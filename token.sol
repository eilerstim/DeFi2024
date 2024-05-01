// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract LuckyToken is IERC20 {
    using SafeMath for uint256;
    //public keysword for state variables creates public getter but not setter
    string public constant name = "LuckyToken";
    string public constant symbol = "LUCK";
    uint8 public constant decimals = 10; 
    uint256 public totalSupply = 0;

    uint256 public transactionCount = 0; // Amount of transactions since last draw
    uint256 public constant lotteryThreshold = 10; // Amount of transaction to trigger a draw
    uint256 public constant lotteryFee = 10; // 10% fee for every transaction
    uint256 private _nonce = 0;
    address[] private _lotteryTickets = new address[](lotteryThreshold);
    address private creator;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;


    constructor() {
        _mint(msg.sender, 777);
        creator = msg.sender;
    }
    //why are some internal and some private?
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function mint(address to, uint value) external returns (bool) {
        if(creator == msg.sender) {
            _mint(to,value);
            return true;
        }
        return false;
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
        uint256 fee = value / lotteryFee;

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
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function _drawLottery() internal {
        // Determine "random" index using hash function
        _nonce++;
        uint i = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,_nonce))) % lotteryThreshold;

        // Transfer from pool to winner
        address winner = _lotteryTickets[i];
        uint256 value = balanceOf[address(0)];
        balanceOf[address(0)] = 0;
        balanceOf[winner] = balanceOf[winner].add(value);

        // Reset counter
        transactionCount = 0;

        emit Transfer(address(0), winner, value);
    }
    
}
