import Commons
import Wallet
import Network
defmodule Transaction do

    @doc """
    Generates the first transaction in the Bitcoin System. This transaction is later used in creating a genesis Block. 
    The genesis transaction does not contain any input transactions. 
    It contains one output field whose value is 50 BTC and public key to which this is sent is “1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa”.
    It is said to be the public key address of creator of Bitcoin, Satoshi Nakamoto. It is never used for any further transactions.
    """
    def genesisTransaction do
        # genesisString = "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
        tId = startTransaction()

        # Input = []
        # output = [
        #     [
        #         50,
        #         generateHash("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
        #     ]
        # ]
        # locktime = time()
        updateInput(tId, [])
        updateOutput(tId, [[50, generateHash("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")]])
        transactionHash = createTxHash(tId)
        updateTxHash(tId, transactionHash)
        # IO.puts "Transaction HAsh" <> transactionHash
        # transactionHash
        tId
    end


    @doc """
    Generates the first transaction in the Bitcoin System. This transaction can be later used in creating a genesis Block.
    The Transaction Arguments will have the State structure as:
        # inputs = [[inputHash, inputSignature, inputPublicKey]...],
        # outputs = [[outputValue, ouputPublicKey]] 
    Example
        iex> Transaction.generateTransaction() 
    Output
        #PID<0.100.0>  // Transaction ID
    """
    def generateTransaction(inputs, outputs) do
        tId = startTransaction()
        updateInput(tId, inputs)
        updateOutput(tId, outputs)
        transactionHash = createTxHash(tId)
        # IO.puts "Transaction HAsh" <> transactionHash
        updateTxHash(tId, transactionHash)
        # IO.puts "Transaction HAsh" <> transactionHash
        # transactionHash
        tId
    end


    @doc """
    Create a sender to receiver transaction. Main features of this transaction are:
        - Get the wallet states of sender and receiver
        - Select unusedTransactions from sender wallet sufficient for the amount to transfer
        - Generate outputs depending on whether the total value of input transactions is greater than the <amount> or not.
        - Update Network TransactionPool.
        - Update sender's Wallet for UnusedTransactions
        - Updatereceiver's Wallet for UnusedTransactions
    The argument is as follows:
        - Sender -  PID of the wallet of the sender
        - Receiver - PID of the wallet of the receiver
        - Amount - Number of BTC to be transferred
    Example
        iex> Transaction.createWalletToWalletTx(#PID<0.100.0, #PID<0.101.0, 20.00) 
    """
    def createWalletToWalletTx(sender,receiver,amount) do
        

		{sname, publicKey, privateKey, allPublicKeys, uTransactions, allTransactions, blockchain, target, networkId, walletBalance} = getWalletState(sender) 
		{rname, receiverPublicKey, _, _, _, _, _, _, _, _} = getWalletState(receiver)
        IO.puts "   Sending #{amount} BTC from Wallet# #{sname} ---> Wallet# #{rname}"

        {inputIds, residualAmount} = getRequiredInputs(publicKey, uTransactions, amount)

        if(residualAmount>=0) do
            
            uTransactions = uTransactions -- inputIds

            inputs = Enum.map(inputIds, fn(x)->
                {_,_, _, _, transactionHash}  = getTxState(x)
                [transactionHash,generateSignature(privateKey,"takemymoney"),publicKey]
            end)

            # IO.puts "Inputsssssssss #{residualAmount}"
            # IO.inspect inputs

            if(residualAmount>0) do # this condition is incase amount to send is less than transaction amount
                outputs = [
                    [amount,receiverPublicKey], #first output is to receiver
                    [residualAmount,publicKey] #second output is to self
                ]

                txId = generateTransaction(inputs,outputs)
                updateNetworkTransactionPool(networkId,txId)
                updateWalletUnusedTransactions(receiver,txId,amount)
                updateWalletUnusedTransactions(sender,txId,residualAmount)

                # IO.puts "outputsssssssssssss"
                # IO.inspect outputs   
            else
                outputs = [
                    [amount,receiverPublicKey]
                ]

                txId = generateTransaction(inputs,outputs)
                updateNetworkTransactionPool(networkId,txId)
                updateWalletUnusedTransactions(receiver,txId,amount)
            end

            Enum.map(inputIds,fn(x)->
                {_, _, outputs, _, _ } = getTxState(x)
                outputTotal = Enum.sum(Enum.map(outputs,fn(y) ->
                    if (publicKey == Enum.fetch!(y, 1)) do  
                        Enum.fetch!(y, 0)
                    else 
                        0 
                    end
                end))
                removeWalletUnusedTransactions(sender,x,outputTotal)
            end)

        # else

        end


    end

    @doc """
    Select unusedTransactions from sender wallet sufficient for the amount to transfer
    """
    def getRequiredInputs(walletPublicKey, uTransactions,amount,finalList \\ [],i \\ 0) do
        if(i < length(uTransactions)) do
            x = Enum.fetch!(uTransactions, i)

            {_, _, outputs, _, _ } = getTxState(x)
            outputTotal = Enum.sum(Enum.map(outputs,fn(y) ->
                if (walletPublicKey == Enum.fetch!(y, 1)) do  
                    Enum.fetch!(y, 0)
                else 
                    0 
                end
            end))

            if (outputTotal >= amount) do
                amount = amount - outputTotal
                finalList = finalList ++ [x]
                {finalList, -1*amount}
            else
                amount = amount - outputTotal
                finalList = finalList ++ [x]
                getRequiredInputs(walletPublicKey,uTransactions,amount,finalList,i + 1)
            end
        else
            IO.puts "Oops! Not enough Bitcoins"
            {[],-1}
        end

    end

    @doc """
        flag - unused
        input []
            - HAsh of prev trx
            - signature
            - public key
            # - script signature
            #     * signature
            #     * public key
        output []
            - value
            - public key
        locktime
        hash
        amount
    """
    def init(:ok) do
        timeStamp = :os.system_time(:millisecond)
        {:ok, {true,[], [], timeStamp, ""}} 
    end
    def startTransaction do
        {:ok,pid}=GenServer.start_link(__MODULE__, :ok,[])
        pid
    end

    def updateFlag(pid,flag) do
        GenServer.call(pid, {:UpdateFlag,flag})
    end
    def handle_call({:UpdateFlag,flag}, _from ,state) do
        {a,b,c,d,e} = state
        state={flag,b,c,d,e}
        {:reply,a,state}
    end

    def updateInput(pid,input) do
        GenServer.call(pid, {:UpdateInput,input})
    end
    def handle_call({:UpdateInput,input}, _from ,state) do
        {a,b,c,d,e} = state
        state={a,input,c,d,e}
        {:reply,b,state}
    end

    def updateOutput(pid,output) do
        GenServer.call(pid, {:UpdateOutput,output})
    end
    def handle_call({:UpdateOutput,output}, _from ,state) do
        {a,b,c,d,e} = state
        state={a,b,output,d,e}
        {:reply,c,state}
    end


    def updateTxHash(pid,hash) do
        GenServer.call(pid, {:UpdateTxHash,hash})
    end
    def handle_call({:UpdateTxHash,hash}, _from ,state) do
        {a,b,c,d,e} = state
        state={a,b,c,d,hash}
        {:reply,e,state}
    end

    def getTxState(tId) do
        GenServer.call(tId,{:GetTxState})
    end

    def handle_call({:GetTxState}, _from ,state) do
        {:reply, state, state}
    end

    def createTxHash(tId) do

        {flag,input,output,timestamp,hash} = getTxState(tId)

        eachInputHashList = Enum.map(input, fn(x) -> 
            Enum.join(x,"")
        end)

        inputsHash = Enum.join(eachInputHashList,"")

        eachOutputHashList = Enum.map(output, fn(x) ->    
            to_string(Enum.fetch!(x,0)) <> Enum.fetch!(x,1)
        end)

        outputsHash = Enum.join(eachInputHashList,"")

        newHash = generateHash(to_string(flag) <> inputsHash <> outputsHash <> to_string(timestamp))

        updateTxHash(tId,newHash)
        newHash

    end

    
    @ecdsa_curve :secp256k1
    @type_signature :ecdsa
    @type_hash :sha256
    def generateSignature(private_key, message) do
        signature = 
            :crypto.sign(
                @type_signature,
                @type_hash, 
                message, 
                [private_key, @ecdsa_curve]
            ) |> Base.encode16
        # {:ok, {0, public_key, private_key, "", [], []}} 
    end

    def verifySignature(public_key, signature, message) do
        :crypto.verify(
            @type_signature, 
            @type_hash, 
            message, 
            signature, 
            [public_key, @ecdsa_curve])
    end
end