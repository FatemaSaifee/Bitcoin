import Commons
import Wallet
import Network
defmodule Transaction do

    def genesisTransaction do
        # genesisString = "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
        tId = startTransaction()

        # Input = []
        # output = [
        #     [
        #         100,
        #         generateHash("")
        #     ]
        # ]
        # locktime = time()
        updateInput(tId, [])
        updateOutput(tId, [[100, generateHash("")]])
        transactionHash = createTxHash(tId)
        updateTxHash(tId, transactionHash)
        # IO.puts "Transaction HAsh" <> transactionHash
        # transactionHash
        tId
    end

    # inputs = [[inputHash, inputSignature, inputPublicKey]...],
    # outputs = [[outputValue, ouputPublicKey]] 
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

            # if(amount>0) do
            
            #     # Enum.map(uTransactions, fn(x) -> 
            #     x = Enum.fetch!(uTransactions, i)
            #         {_, _, outputs, _, _ } = getTxState(x)
            #         Enum.map(outputs,fn(y) ->

            #             if(Enum.fetch!(y,0)>=amount)
            #                 finalList = finalList ++  [x]
            #                 # amount = amount - Enum.fetch!(y,0)
            #             else
            #                 finalList = finalList ++ [x]
            #                 amount = amount - Enum.fetch!(y,0)
            #                 getRequiredInputs(uTransactions,amount,finalList,i+1)
            #             end
            #         end)
            #     # end)
            # else

            # end


    end

    @doc """
        # flag
        # witnesses
        # in-count
        # out-count
        # header

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