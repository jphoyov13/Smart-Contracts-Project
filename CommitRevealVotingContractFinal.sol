// ************* HERE STARTS THE VOTING TOKEN CONTRACT *******************

/*  
    ---The purpose of this Smart Contract---
    The VoteToken contract is an ERC-20–compatible token that serves as the voting currency 
    in our commit–reveal voting system. It implements the standard 
    ERC-20 interface (balances, allowances, transfers, and events) and uses the OpenZeppelin Ownable module 
    to ensure that only the administrator can mint new tokens or configure the voting contract. 
    In our architecture, VoteToken is purchased by users through the pricing contract and later locked as voting weight during the commit phase.
    
*/



// SPDX-License-Identifier: MIT
/*  (1): As stated in the lecture slides smart contracts must include a license identifier,
         in our case MIT is the default commonly used open-source license
         comment required by Solidity to make public to the world.
         Source: Solidity Basics PDF, lecture slides
 */




pragma solidity ^0.8.9;
/*  (2): The instruction that tells solidity the compiler version to be used,
         from 0.8.9 up to, but not including, 0.9.0
         Source: Solidity Basics PDF, lecture slides
 */


import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/access/Ownable.sol";
/* (3): We are pulling an already made contract by OpenZeppelin (the industry standard library for Solidity).
         Downloads the file and compiles it together with our VoteToken contract.
         Makes all its functions and variables usable inside our contract through inheritance.
         Source: OpenZeppelin Github, https://raw.githubusercontent.com/OpenZeppelin/openZeppelin-contracts/v4.8.3/contracts/access/Ownable.sol
         Library name: OpenZeppelin Contracts
         We imported Ownable to give the VoteToken contract a single admin address (the owner). 
         We wanted to reuse a standard, audited access-control module instead of writing our own owner logic from scratch, to follow best practices.
         Sample with imported contracts where we got inspired from: https://github.com/Uniswap/v3-periphery/blob/main/contracts/V3Migrator.sol
 */




contract VoteToken is Ownable {
/*  (4): Creates a smart contract called VoteToken.
         This contract inherits all the features of the Ownable contract I imported earlier.
         un restricted functions like mint or setVotingContract.
         Sample with imported contracts where we got inspired from: https://github.com/Uniswap/v3-periphery/blob/main/contracts/V3Migrator.sol
         Source: Account Model PDF, lecture slides
 */


    // 1. Token metadata
    string public name;
    string public symbol;
    uint8 public decimals;

/*  (5): This is just a comment grouping the variables that define identity information of the token.
         It tells wallets what the token should be called, what its symbol is, and how many decimals it uses.
         These fields (name, symbol, decimals) are part of the standard token metadata model used in ERC-20 and ERC-721.
         Library name: OpenZeppelin Contracts
         Source: Real ERC-20 metadata fields in OpenZeppelin
         Sample: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
         Source: Tokenization Introduction PDF, lecture slides
         string public name; --> This is the full name of our token. Because it’s public, Solidity automatically creates a function name().
         string public symbol; --> This is our token’s ticker symbol.
         uint8 public decimals; --> This tells the wallet how many decimal places the token has.
         These three metadata variables (name, symbol, decimals) are required by 
         standard ERC-20 implementations and follow the same structure used in 
         OpenZeppelin’s ERC-20 contract, allowing wallets to recognize and display the token correctly.
*/

    // 2. ERC-20 state
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;


/*(6):  This is just a comment that will show the state of our ERC-20 Token.
         We create a uint256, that will later be created as a function, in which we will use to find out the total supply of tokens.
         mapping(address => uint256) private balances; --> stores how many tokens each address owns. We need it so that we know who owns which Tokens.
         mapping(address => mapping(address => uint256)) private allowed; --> This is a nested mapping that stores 
         how many tokens one address allows another address to spend. These allows other contracts to move Tokens with Permission.
         Source: Tokenization Introduction PDF, lecture slides
*/



    // 3. Voting contract that is allowed to mint/burn 
    address public votingContract;

/*  (7):  votingContract is the only one allowed to create (mint) or destroy (burn) these VoteTokens.
          These variobale stores one address on the Blockchain, will be created as a function.
          Source: address public votingContract; stores the address of the Commit-Reveal voting contract. 
          It is a custom variable added by our group to link the VoteToken to the voting mechanism. 
          It is not part of the ERC-20 standard and does not appear in the lecture slides. 
          We use it so that only the designated voting contract can mint or burn tokens via the onlyVotingContract modifier.
          Sample: A similar pattern is used in existing BEP-20 tokens on BNB Smart Chain, which also expose an address public votingContract;
          Source: https://vscode.blockscan.com/56/0x8a682cc16df6574801ae578c3858f0dac44398c7?utm_source=chatgpt.com
*/




    // 4. ERC-20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

/*  (8):  Here we define the events that every ERC-20 token should have. 
          An event is like a log message that the blockchain writes when something happens.
          This event is used every time tokens move from one address to another.
          This event is emitted when someone gives permission to another address to spend their tokens.
          Source: Tokenization Introduction PDF, lecture slides
*/


    // 5. Constructor: create initial supply and basic token data
    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;

        emit Transfer(address(0), msg.sender, _initialAmount);
    }

/* (9):
      This comment tells us that the next part will set up the token the moment the contract is deployed.
      The constructor is a special function that runs only once in the entire lifetime of the contract.
      _initialAmount tells the contract how many tokens should exist at the beginning.
      _tokenName allows us to select a readable name for the token.
      _decimalUnits defines how many decimal places the token uses .
      _tokenSymbol is the short version of the token name, like “CLC” or “VOTO”.
      Inside the constructor, we give all the newly created tokens to msg.sender (the deployer of the contract).
      totalSupply is set equal to the amount of tokens we just created.
      The token name, decimals, and symbol are saved so wallets can display them correctly.
      We emit a Transfer event from address(0) to show that the tokens were minted out of nowhere.
      This is the standard ERC-20 way to signal initial token creation.
      Source: Tokenization Introduction PDF, lecture slides
*/



    // 6. Standard ERC-20 functions (unchanged)
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        require(balances[_from] >= _value, "Insufficient balance");

        if (allowed[_from][msg.sender] < type(uint256).max) {
            allowed[_from][msg.sender] -= _value;
        }

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }


/* (10):

      This part of the code contains all the standard ERC-20 functions that every token must have.
      These functions follow the official ERC-20 interface exactly, so other smart contracts and wallets
      can interact with our token without problems.

      balanceOf():
          This function lets anyone check how many tokens a specific address owns.
          It does not change anything on the blockchain; it only reads the balance from the mapping.

      transfer():
          This sends tokens from my own account (msg.sender) to another address.
          We check first that I have enough tokens.
          Then we subtract the amount from my balance and add it to the receiver’s balance.
          We emit a Transfer event so wallets like MetaMask can show the transaction.

      transferFrom():
          This allows a smart contract or another address to send tokens on behalf of someone else.
          First we check that the caller (msg.sender) has enough allowance.
          Then we check that the _from address actually has the tokens.
          If the allowance is not unlimited, we reduce it.
          Then we move the tokens and emit a Transfer event.
          This is what DEXs (like Uniswap) use when you swap tokens.

      approve():
          This function gives another address permission to spend my tokens.
          We store how much they can spend in the allowed mapping.
          We emit an Approval event so contracts know the new allowance.

      allowance():
          This shows how many tokens a spender is allowed to spend from an owner’s account.
          It only reads from the allowed mapping and does not change anything.

      These functions together make the token fully ERC-20 compliant, meaning it behaves exactly like
      every other ERC-20 token on Ethereum.

      Source: Tokenization Introduction PDF, lecture slides
              
*/



    // 7. Custom logic for voting system

    modifier onlyVotingContract() {
        require(msg.sender == votingContract, "Not voting contract");
        _;
    }

    // Can be called once to set the voting contract address (unchanged behavior)
    function setVotingContract(address _votingContract) external {
        require(votingContract == address(0), "Voting contract already set");
        votingContract = _votingContract;
    }

    // Mint votes to a user when called by the voting contract (unchanged)
    function mintForVoting(address _to, uint256 _amount) external onlyVotingContract {
        totalSupply += _amount;
        balances[_to] += _amount;

        emit Transfer(address(0), _to, _amount);
    }

    // Burn votes when a user spends them to vote (unchanged)
    function burnForVoting(address _from, uint256 _amount) external onlyVotingContract {
        require(balances[_from] >= _amount, "Not enough balance to burn");

        balances[_from] -= _amount;
        totalSupply -= _amount;

        emit Transfer(_from, address(0), _amount);
    }


    /**
     * owner-only mint function
     *  - added so token owner can mint tokens to the VotePricing contract for pre-funding
     *  - this is the only new externally-visible owner function (safe and minimal)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "mint to zero");
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

/* (11):
      This whole block is the “custom logic” that connects our ERC-20 token to the voting system.
      The general ideas of modifiers and events come from the lectures, but the concrete functions
      (onlyVotingContract, setVotingContract, mintForVoting, burnForVoting, mint) are custom-made
      for our project and are NOT directly in the slides.

      modifier onlyVotingContract() {
          require(msg.sender == votingContract, "Not voting contract");
          _;
      }
          This is a custom modifier that we created.
          It makes sure that only the votingContract address is allowed to call certain functions.
          require(...) checks that msg.sender is exactly the stored votingContract.
          The "_;" means: if the require passes, continue with the rest of the function.
          Source: Functions and Modifiers PDF 

      function setVotingContract(address _votingContract) external {
          require(votingContract == address(0), "Voting contract already set");
          votingContract = _votingContract;
      }
          This function sets the address of the voting contract exactly once.
          We check that votingContract is still address(0), so we cannot overwrite it later.
          This prevents someone from swapping the voting contract to a malicious one.
          Marked external so only outside callers can use it, but not internal logic.
          Source: This exact function is NOT in the slides; it is custom for our voting system.

      function mintForVoting(address _to, uint256 _amount) external onlyVotingContract {
          totalSupply += _amount;
          balances[_to] += _amount;
          emit Transfer(address(0), _to, _amount);
      }
          This function is called by the voting contract when it wants to give a user voting tokens.
          Because of onlyVotingContract, nobody else can mint these tokens.
          We increase totalSupply, because we are creating new tokens.
          We increase the balance of _to by the minted amount.
          We emit a Transfer event from address(0) to show that these tokens were minted.
          The minting pattern (using address(0)) follows the example from the constructor in the Tokenization slides,
          but the voting-specific purpose (mintForVoting) is custom.
          

      function burnForVoting(address _from, uint256 _amount) external onlyVotingContract {
          require(balances[_from] >= _amount, "Not enough balance to burn");
          balances[_from] -= _amount;
          totalSupply -= _amount;
          emit Transfer(_from, address(0), _amount);
      }
          This function is called by the voting contract when a user spends their votes.
          We first check that _from actually has enough voting tokens to burn.
          We reduce the user’s balance and also reduce totalSupply, because tokens are destroyed.
          We emit a Transfer event to address(0) to signal that tokens were burned.
          Source: Again, the burn pattern (Transfer to address(0)) is consistent with common ERC-20 practice,
          but the exact burnForVoting function is custom and not in the lecture slides.

      function mint(address to, uint256 amount) external onlyOwner {
          require(to != address(0), "mint to zero");
          totalSupply += amount;
          balances[to] += amount;
          emit Transfer(address(0), to, amount);
      }
          This is an extra mint function that only the contract owner is allowed to call.
          onlyOwner comes from the imported OpenZeppelin Ownable contract, not from the slides.
          We use it so the token owner can pre-fund other contracts (like a VotePricing contract) with tokens.
          We do not allow minting to the zero address to avoid mistakes.
          Just like mintForVoting, we increase totalSupply and the recipient’s balance, and emit a Transfer from address(0).
          This function is not in the lecture slides; it is custom for our project.
          Source: OpenZeppelin Ownable.sol (imported in our code).

      Summary:
          – Modifiers, events, and the idea of using address(0) for mint/burn come from the lecture material.
          – The specific functions onlyVotingContract, setVotingContract, mintForVoting, burnForVoting, and mint
            are custom-designed for our voting token use case and are not directly present in the slides.
*/

// ************* HERE STARTS THE TIERED PRICING CONTRACT *******************
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*(Ref: 4)*/

/*Tiered pricing contract
This smart contract lets users buy ERC20 vote tokens with ETH using a quadratic pricing formula where each additional vote costs more than the last. 
The contract safely handles payments, refunds, and allows the owner to update prices or withdraw accumulated ETH.*/

/*References:

(1) ChatGPT (OpenAI) and Remix AI Assistant.
Used as educational tools for learning Solidity, understanding contract architecture, explaining code behavior, and suggesting non-original improvements. Tools were used for clarification, debugging support, and improved readability.
Retrieved: 2025.

(2) Schaer, F. “Functions and Modifiers.” Cryptolectures.
https://cryptolectures.teachable.com/courses/1526166/lectures/36185995
Retrieved: Nov 2025.

(3) Schaer, F. “Global Variables, Transfers and Events.” Cryptolectures.
https://cryptolectures.teachable.com/courses/1526166/lectures/36404113
Retrieved: Nov 2025.

(4) Schaer, F. “Solidity Basics.” Cryptolectures.
https://cryptolectures.teachable.com/courses/1526166/lectures/36139224
Retrieved: Nov 2025.

(5) OpenZeppelin Contracts v4.8.3 — IERC20 Interface.
https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/token/ERC20/IERC20.sol
Retrieved: Nov 2025.

(6) OpenZeppelin Contracts v4.8.3 — SafeERC20 Library.
https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol
Retrieved: Nov 2025.

(7) OpenZeppelin Contracts v4.8.3 — Ownable Module.
https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/access/Ownable.sol
Retrieved: Nov 2025.

(8) OpenZeppelin Contracts v4.8.3 — ReentrancyGuard Module.
https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/security/ReentrancyGuard.sol
Retrieved: Nov 2025.*/



/*(Import IERC20 interface) (Ref: 5)
Provides the standard ERC20 function definitions (balanceOf, transfer, allowance, etc.), used so the contract can interact with an existing ERC20 token.*/
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/token/ERC20/IERC20.sol";

/*(Import SafeERC20 library) (Ref: 6)
Adds safe wrappers around ERC20 transfers,prevents silent failures and protects against non-standard token behavior.*/
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

/*(Import ownable) (Ref: 7)
Gives the contract an "owner" (the admin), only the owner can change settings like price.*/
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/access/Ownable.sol";

/*(Import Reentrancy guard) (Ref: 8)
This prevents reentrancy attacks by ensuring a function cannot be re-entered before it finishes, it is used below as "nonReentrant"*/
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.3/contracts/security/ReentrancyGuard.sol";


/*(The contract starts here) (Ref: 5,6,7,1)
Says this contract sells vote tokens using tier-based (quadratic) pricing.*/
contract VotePricing is Ownable, ReentrancyGuard { // main contract with ownership and reentrancy protection
    using SafeERC20 for IERC20; // attach SafeERC20 helpers to IERC20 type


    /* (The token we are selling) (Ref: 5,1)
       This is the ERC20 VoteToken, users will receive this token when they buy votes.*/
    IERC20 public voteToken;  // ERC20 token contract address used as vote token

    /* (Base price) (Ref: 1)
       This is the basic cost number used in the quadratic formula.*/
    uint256 public basePrice; // price unit (in wei) multiplied by squared tier


    /* (Record of how many votes each user has bought) (Ref: 1)
       We keep track so we know how expensive future votes should be.*/
    mapping(address => uint256) public votesPurchased; // tracks total votes bought per address


    /* (Events) (Ref: 1)
       These are messages that appear on the blockchain to see what happened, they are useful for debugging and transparency.*/
    event VotesPurchased(address indexed buyer, uint256 newVotes, uint256 cost); // emitted on successful purchase
    event RefundIssued(address indexed buyer, uint256 amount); // emitted when refund occurs
    event BasePriceUpdated(uint256 oldPrice, uint256 newPrice); // emitted when owner updates base price
    event Withdrawn(address indexed owner, uint256 amount); // emitted when owner withdraws ETH


    /* (Constructor) (Ref: 3,5,1)
       This runs once when the contract is deployed, and sets which token we are selling and what the starting price is.*/
    constructor(address _voteToken, uint256 _basePrice) // constructor with token address and base price
    {
        require(_voteToken != address(0), "token zero address"); // ensure token address is valid
        require(_basePrice > 0, "basePrice>0"); // ensure base price is positive

        voteToken = IERC20(_voteToken); // store the token interface
        basePrice = _basePrice; // store the base price
    }

    /* (Quadratic function) (Ref: 2,1)
       This function calculates the total ETH cost for buying newVotes with the quadratic function cost = (vote#)^2 * basePrice.*/
    function getCost(uint256 currentVotes, uint256 newVotes) public view returns (uint256) { // compute total cost
        unchecked { // use unchecked to save gas for arithmetic where overflow is not expected
            uint256 total = 0; // accumulator for total cost

            // Loop through each new vote and calculate its tier price
            for (uint256 i = 1; i <= newVotes; i++) { // iterate from 1 to newVotes inclusive
                uint256 voteNumber = currentVotes + i; // absolute vote index after purchase
                total += voteNumber * voteNumber * basePrice; // add (voteNumber^2 * basePrice)
            }

            return total; // return total cost in wei
        }
    }

    /* (Buying votes) (Ref: 2,8,1)*/
    function buyVotes(uint256 newVotes) 
        external 
        payable 
        nonReentrant   // (Prevents Reentrancy attacks)
    {
        require(newVotes > 0, "buy at least 1 vote"); // must request at least one vote

        uint256 current = votesPurchased[msg.sender]; // read how many votes caller already bought
        uint256 cost = getCost(current, newVotes); // compute required ETH cost

        require(msg.value >= cost, "Not enough ETH sent"); // require sender sent enough ETH

        // (Make sure the contract has enough tokens to give) (Ref: 5,1)
        uint256 tokenBalance = voteToken.balanceOf(address(this)); // token balance of this contract
        require(tokenBalance >= newVotes, "Not enough vote tokens in contract"); // need enough tokens


        /* (Update state first) (Ref: 1)
           Follows the Checks-Effects-Interactions pattern to prevent reentrancy and incorrect calculations.*/
        votesPurchased[msg.sender] = current + newVotes; // update buyer’s stored vote count


        /* (Send tokens to buyers) (Ref: 5,6,1)
           SafeERC20 ensures this cannot fail silently.*/
        voteToken.safeTransfer(msg.sender, newVotes); // send newVotes tokens to buyer (units must match token)


        /* (Refund extra ETH if the user sent too much) (Ref: 1)
           Uses .call (safer than .transfer) to safely send ETH back to the user and checks that the transfer succeeded.*/
        uint256 refund = msg.value - cost; // calculate refund amount
        if (refund > 0) { // only refund when necessary
            (bool ok, ) = payable(msg.sender).call{value: refund}(""); // safe ETH refund via call
            require(ok, "Refund failed"); // revert if refund fails
            emit RefundIssued(msg.sender, refund); // emit refund event
        }

        emit VotesPurchased(msg.sender, newVotes, cost); // emit purchase event
    }

    /* (Owner withdraw function) (Ref: 2,8,7,1)
       The contract will receive lots of ETH from buyers, only the owner can withdraw it safely.*/
    function withdraw() external onlyOwner nonReentrant { // withdraw contract ETH, only owner
        uint256 bal = address(this).balance; // read ETH balance
        require(bal > 0, "No ETH to withdraw"); // require non-zero balance

        (bool ok, ) = payable(owner()).call{value: bal}(""); // send ETH to owner
        require(ok, "Withdraw failed"); // revert if send fails

        emit Withdrawn(owner(), bal); // emit event
    }

    /* (Change price) (Ref: 2,7,1)
       Owner can adjust basePrice if needed.*/
    function setBasePrice(uint256 _new) external onlyOwner { // update base price, owner only
        require(_new > 0, "Price must be > 0"); // ensure new price positive

        uint256 old = basePrice; // store old price
        basePrice = _new; // set new price

        emit BasePriceUpdated(old, _new); // emit update event
    }

    /* (Fallback functions) (Ref: 1)
       Allow the contract to receive ETH safely.*/
    receive() external payable {} // receive ETH function
    fallback() external payable {} // fallback payable
}


// ************* HERE STARTS THE COMMIT REVEAL VOTING CONTRACT *******************

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

  CommitRevealVoting.sol
  - Binary (Yes/No) commit-reveal voting with:
      * ETH deposit at commit that is refunded on reveal or slashed after finish to mitigate griefing (commiting but not revealing)
      * nonReentrant protection via simple mutex
    
*/

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
 
contract CommitRevealVoting {
    // Types 
    enum Phase { Commit, Reveal, Finished }   // [Commit = 0; Reveal = 1; Finished = 2]
    // (1) Adopted from video lectures  
       // Source: https://cryptolectures.teachable.com/courses/1526166/lectures/36404113
       // Author:  Prof. Dr. Fabian Schaer: Cryptolectures
       // Retrieved: Nov 2025
       // RemixAI Assistant Copilot, OpenAIs ChatGPT as well as Microsoft Copilot were used as tools alongside the lecture material 
       // for deeper understanding in a "micro" level (each function, variable and useful semantics) as well as at the "macro" level merging 
       // with the other two contracts as well as for debugging and gathering appropiate functions. 

    struct CommitInfo {
        bytes32 commitHash;
        bool revealed;
        uint256 committedAt;
    }

    // State Variables: (variables that live and persist in the contract storage; are written on the blockchain thus cost gas; do not belong to/inside functions)
    address public admin;
    IERC20Minimal public votingToken; // token interface to interact with ERC20 token contract

    uint256 public commitEnd;          // timestamp when commit phase ends       
    uint256 public revealEnd;         // timestamp when reveal phase ends        
    uint256 public depositAmountWei; // required ETH deposit at commit (slashed if unrevealed)

    mapping(address => CommitInfo) public commits;
    mapping(address => uint256) public lockedWeight;  // to check how much Token weight was locked when voting
    mapping(address => uint256) public deposits;     // to check ETH deposits per voter and helps to see if refunded succefull or not

    uint256 public totalYesWeight;        // Returns the total weight of YES votes, 
    uint256 public totalNoWeight;        // Returns the total weight of NO votes
    uint256 public totalRevealedWeight; // Returns the total weight of revealed votes

    // reentrancy guard variable,  (2) adopted from: https://www.quicknode.com/guides/ethereum-development/smart-contracts/common-solidity-vulnerabilities-on-ethereum 
    //                                               https://docs.soliditylang.org/en/latest/contracts.html
    uint256 private _locked;

    // Events: 
    event Committed(address indexed voter, bytes32 commitHash, bool lockedAtCommit, uint256 lockedWeight);
    event Revealed(address indexed voter, uint8 vote, uint256 weight, bool depositRefunded);
    event DepositRefunded(address indexed voter, uint256 amount);
    event DepositPendingRefund(address indexed voter, uint256 amount);
    event DepositSlashed(address indexed voter, uint256 amount, address to);
    event TokensSlashed(address indexed voter, uint256 amount, address to);

    //  Modifiers: to restrict functions according to contract flow
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyDuringPhase(Phase p) {
        require(currentPhase() == p, "wrong phase");
        _;
    }

    modifier nonReentrant() {   // reentrancy guard (simple mutex) see reference with variable above (2)
        require(_locked == 0, "reentrancy");
        _locked = 1;
        _;
        _locked = 0;
    }

    //  Constructor parameters: what will be set at deployment by contract owner account 
    /*
     _votingToken: ERC20 token address used as voting weight
     _commitDurationSeconds, _revealDurationSeconds: durations for phases
     _depositAmountWei: amount of ETH deposit required to commit. */ 
       // (3) Adopted from video lectures  
       // Source: https://cryptolectures.teachable.com/courses/1526166/lectures/36404113
       // Author:  Prof. Dr. Fabian Schaer: Cryptolectures
       // Retrieved: Nov 2025
    
    constructor(
        address _votingToken,
        uint256 _commitDurationSeconds,
        uint256 _revealDurationSeconds,
        uint256 _depositAmountWei  // deposit > 0.0 ETH to avoid mitigate griefing attach
    ) {
        require(_votingToken != address(0), "token zero");
        require(_commitDurationSeconds > 0 && _revealDurationSeconds > 0, "durations>0");
        admin = msg.sender;
        votingToken = IERC20Minimal(_votingToken);
        commitEnd = block.timestamp + _commitDurationSeconds;
        revealEnd = commitEnd + _revealDurationSeconds;
        depositAmountWei = _depositAmountWei;
    }

    // Phase helper: to show current phase of voting [Commit = 0; Reveal = 1; Finished = 2] 
    function currentPhase() public view returns (Phase) {
        if (block.timestamp <= commitEnd) {
            return Phase.Commit;
        } else if (block.timestamp <= revealEnd) {
            return Phase.Reveal;
        } else {
            return Phase.Finished;
        }
    }

    // Commit phase:
       // (4) Adopted from video lectures 
       // Source: https://cryptolectures.teachable.com/courses/1526166/lectures/34942441
       // Author:  Prof. Dr. Fabian Schaer: Cryptolectures
       //Retrieved: Nov 2025
       // As well as with assistance of AI Tools mentioned on top
    // Voter/caller must send depositAmountWei as Value and must have 
    // approved this contract as spender for `weight` in token contract before commiting. It locks tokens immediately when committing
    
    function commitAndLock(uint256 weight, bytes32 commitHash) external payable onlyDuringPhase(Phase.Commit) nonReentrant {
        require(commitHash != bytes32(0), "empty hash");
        CommitInfo storage info = commits[msg.sender];
        require(info.commitHash == bytes32(0), "already committed");
        require(msg.value == depositAmountWei, "deposit incorrect");
        require(weight > 0, "weight>0"); // voter must have minimal token weight due to voting token right

        // transfer tokens from voter to lock them
        bool ok = votingToken.transferFrom(msg.sender, address(this), weight);
        require(ok, "token transferFrom failed");

        // store commit, locked weight and deposit
        info.commitHash = commitHash;
        info.committedAt = block.timestamp;  // <- not necesary but low-cost addition for transparency
        lockedWeight[msg.sender] = weight;  
        deposits[msg.sender] += msg.value;

        emit Committed(msg.sender, commitHash, true, weight);
    }
    // Commit hash generator:
       // (5) Adopted from video lectures 
       // Source: https://cryptolectures.teachable.com/courses/1526166/lectures/36448699
       // Author:  Prof. Dr. Fabian Schaer: Cryptolectures
       // Retrieved: Nov 2025
    function generateCommitHash( uint8 vote, uint256 weight, string memory secret ) public view returns (bytes32 commitHash) {
    commitHash= keccak256( abi.encode(vote, weight, secret, msg.sender) ); // here is the hash encoding process to create sealed vote
    }

    // Reveal phase: 
       // (6) Adopted from video lectures 
       // Source: https://cryptolectures.teachable.com/courses/1526166/lectures/34942441
       // Author:  Prof. Dr. Fabian Schaer: Cryptolectures
       // Retrieved: Nov 2025
       // As well as with assistance of AI Tools mentioned on top
    // vote: 0 => No, 1 => Yes
    function reveal(uint8 vote, uint256 weight, string calldata secret)
        external onlyDuringPhase(Phase.Reveal) nonReentrant {
        require(vote == 0 || vote == 1, "vote 0/1");
        CommitInfo storage info = commits[msg.sender];
        require(info.commitHash != bytes32(0), "no commit");
        require(!info.revealed, "already revealed");
        require(weight > 0, "weight>0");

        // Recreate commit hash (must match exact commit hash enconding
        bytes32 expected = keccak256(abi.encode(vote, weight, secret, msg.sender));
        require(expected == info.commitHash, "commitment mismatch");
        require(lockedWeight[msg.sender] == weight, "weight mismatch with locked");
            // tokens already held in contract

        // mark revealed and add vote & weight to totals
        info.revealed = true;
        if (vote == 1) totalYesWeight += weight;
        else totalNoWeight += weight;
        totalRevealedWeight += weight;

        // attempt to refund deposit immediately
        uint256 dep = deposits[msg.sender];
        bool refunded = false;
        if (dep > 0) {
            // zero-out deposit first to avoid reentrancy issues
            deposits[msg.sender] = 0;
            (bool sent, ) = msg.sender.call{value: dep}("");
            if (sent) {
                refunded = true;
                emit DepositRefunded(msg.sender, dep);
            } else {
                // failed to send -> restore deposit mapping so user can claim later
                deposits[msg.sender] = dep;
                emit DepositPendingRefund(msg.sender, dep);
            }
        }

        emit Revealed(msg.sender, vote, weight, refunded);
    }

    //  Claim refund option (if automatic refund failed or admin hasn't slashed)
    function claimRefund() external nonReentrant {
        CommitInfo storage info = commits[msg.sender];
        require(info.commitHash != bytes32(0), "no commit");
        require(info.revealed, "not revealed");
        uint256 dep = deposits[msg.sender];
        require(dep > 0, "no deposit");
        deposits[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: dep}("");
        require(sent, "refund failed");
        emit DepositRefunded(msg.sender, dep);
    }

    // Admin utility: slash unrevealed commits (after Finished)
    // - if they committed but did not reveal: transfer their deposit to `to` and transfer any locked tokens to `to`.
    // - clears their stored state so funds can't be double-slashed.
     // Adopted with assistance of AI Tools mentioned on top
    function adminSlashUnrevealed(address[] calldata voters, address to) external onlyAdmin nonReentrant {
        require(currentPhase() == Phase.Finished, "not finished");
        require(to != address(0), "zero to");
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            CommitInfo storage info = commits[voter];
            if (info.commitHash == bytes32(0)) continue; // no commit
            if (info.revealed) continue; // already revealed so skip

            // slash deposit
            uint256 dep = deposits[voter];
            if (dep > 0) {
                deposits[voter] = 0;
                (bool sent,) = to.call{value: dep}("");
                if (sent) {
                    emit DepositSlashed(voter, dep, to);
                } else {
                    // if sending ETH to `to` fails, restore deposit for admin to try later
                    deposits[voter] = dep;
                }
            }

            // slash tokens locked at commit
            uint256 lw = lockedWeight[voter];
            if (lw > 0) {
                lockedWeight[voter] = 0;
                bool ok = votingToken.transfer(to, lw);
                if (ok) {
                    emit TokensSlashed(voter, lw, to);
                } else {
                    //  no further action if token transfer fails 
                }
            }

            // clear commit so it can't be used later
            delete commits[voter];
        }
    }

    //  Get results:
    // returns 0 if No is greater, 1 if Yes is greater, 2 for a Tie (equal)
    function winningOutcome() external view returns (uint8) {
        if (totalYesWeight > totalNoWeight) return 1;
        if (totalNoWeight > totalYesWeight) return 0;
        return 2;
    }

    function yesVotes() external view returns (uint256) { return totalYesWeight; }
    function noVotes() external view returns (uint256) { return totalNoWeight; }

    // Admin helper: Admin can withdraw tokens or stuck ETH after voting finished if necessary.
    // Adopted with assistance of AI Tools mentioned on top
    function adminWithdrawTokens(address to, uint256 amount) external onlyAdmin nonReentrant {
        require(currentPhase() == Phase.Finished, "not finished");
        require(to != address(0), "zero to");
        bool ok = votingToken.transfer(to, amount);
        require(ok, "token transfer failed");
    }

    function adminWithdrawETH(address payable to, uint256 amount) external onlyAdmin nonReentrant {
        require(currentPhase() == Phase.Finished, "not finished");
        require(to != address(0), "zero to");
        (bool sent,) = to.call{value: amount}("");
        require(sent, "eth transfer failed");
    }

   
}
