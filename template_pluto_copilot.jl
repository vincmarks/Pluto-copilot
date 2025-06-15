### A Pluto.jl notebook ###
# v0.20.9

using Markdown
using InteractiveUtils

# ╔═╡ 5d9a3300-902b-4a5f-ae9e-6b05f26ed572
using PlutoUI, HTTP, JSON, OpenAI, HypertextLiteral, LaTeXStrings

# ╔═╡ 96a9b098-9e2f-4da7-aa3c-d8e760e699f2
using MacroTools, Pluto

# ╔═╡ cb09ac75-9dad-4916-a0f4-0cac3fa03336
md"
# Template for a copilot like funktionality in Pluto notebooks
"

# ╔═╡ 05d4f57b-cb02-464c-9e18-f0b5b21ce7dc
md"""

!!! note
    We will use an API key to access the AI client. Here github marketplace is used for this. Otherwise you could also use your OpenAI API key. However, you have to pay for it in the long term. For this go to [github marketplace/models/catalog ](https://github.com/marketplace?type=models). Now you can choose your desired LLM (I choose [GPT-4o](https://github.com/marketplace/models/azure-openai/gpt-4o) in this file). 
	Click 
	- **<> Use this model**, 
	- then **Get developer key**, 
	- then **generate new token**
	- then **generate new token (classic)**.
	Choose a **Note** for your key and an **expiration date**. Go down the page and click **Generate token**. Copy this token and insert it in **github_token** in this notebook. It is recommended to not share this key with other people. 
	To add this key to our application you can have a look on **Playground** when you choose your desired LLM and click on **code**. Here you will see how to connect to the API.
"""

# ╔═╡ c53944f6-8dd0-4a79-a2b6-1c10b9a428db
md"
## Load your packages and insert your github_token
"

# ╔═╡ f4c593b3-93d2-4197-88e0-cd1d971e75ec
begin
	#Here you have to insert your github_token as described above and the corresponding LLM client. base_url can be found in the code found in Playground
	 github_token = "enter_your_token_here"
     model = "openai/gpt-4o"  
	 base_url = "https://models.github.ai/inference" 	
end

# ╔═╡ 0dc860c5-b320-4e3c-acc3-43abdf32d2d9
md"
## Ask general questions to the LLM. You can also ask questions regarding your notebook
"

# ╔═╡ 1b61ad8b-706d-4f21-9460-f66f3e3cb821
md"""
!!! note
	By writing questions in **ask** you can ask general questions to the LLM.
"""

# ╔═╡ 60859a39-519d-4a53-9160-932b793f9357
begin
	    # loading notebook content with clean_code so you can also ask questions regarding this notebook
	    notebook_content = read("template.jl", String)
	    
	    # Filter out ALL Pluto-specific lines
	    lines = split(notebook_content, '\n')
	    code_lines = filter(line -> 
	        !startswith(line, "# ╔═╡") && 
	        !startswith(line, "# ╠═") && 
	        !startswith(line, "# ╟─") &&
	        !startswith(line, "# ╚═") &&
	        !startswith(line, "# ╞═") &&
	        !startswith(line, "# ╡") &&
	        !startswith(line, "### A Pluto.jl notebook") &&
	        !contains(line, "PlutoUI") &&
	        !contains(line, "PlutoRunner") &&
	        !contains(line, "Pluto.jl") &&
	        !startswith(line, "uuid") &&
	        !startswith(line, "version") &&
	        line != "" || (line == "" && !isempty(strip(line))), lines)
	    
	    clean_code = join(code_lines, '\n')
	end

# ╔═╡ 04570601-84a5-4c5a-b7fc-0b0d1b3d8313
ask = """
	 What was the temperature on average in Germany in 1940?
	"""

# ╔═╡ 57f92ae8-2e24-4390-9a86-206da6e3ed05
begin
	# clean_code contains all infos of this notebook. So you can also ask questions regarding this notebook. clean_code is defined 
	begin
	    function github_models_chat_basic(token, model_name, messages)
	        headers = [
	            "Authorization" => "Bearer $token",
	            "Content-Type" => "application/json"
	        ]
	        
	        body = JSON.json(Dict(
	            "model" => model_name,
	            "messages" => messages,
	            "temperature" => 1,
	            "max_tokens" => 4096,
	            "top_p" => 1
	        ))
	        
	        response = HTTP.post(
	            "$base_url/chat/completions",
	            headers,
	            body
	        )
	        
	        return JSON.parse(String(response.body))
	    end
	
	    function smart_complete_basic(user_question)
	        # Validation of the input
	        if isempty(strip(user_question))
	            return "Please ask a specific question..."
	        end
	        
	        # Intelligent prompt based on question type
	        if occursin(r"code|funktion|plot|julia|programmier", lowercase(user_question))
	            # Code question
	            completion_prompt = """
	            Kontext: I am working in a Pluto.jl notebook with the following previous code:
	            
	            ```julia
	            $clean_code
	            ```
	            
	            My question: $user_question
	            
	            Please answer in English and provide concrete, working Julia examples for code questions.
	            """
	        else
	            # general question
	            completion_prompt = """
	            Question: $user_question
	            
	            Please answer precisely and helpfully in English.
	            """
	        end
	        
	        try
				#when telling the LLM that it is helpful it gives sometimes better outputs
	            messages = [
	                Dict("role" => "system", "content" => "You are a helpful Julia programming assistant and answer questions precisely in English. For code questions, you provide practical, working examples."),
	                Dict("role" => "user", "content" => completion_prompt)
	            ]
	            
	            response = github_models_chat_basic(github_token, model, messages)
	            return response["choices"][1]["message"]["content"]
	        catch e
	            return "Error when retrieving the response: $e"
	        end
	    end
	end
	
	# Main logic for the question
	begin
	    # look if 'ask' exists and is notempty
	    if @isdefined(ask) && !isempty(strip(ask))
	        completion_result_basic = smart_complete_basic(ask)
	        
	        # A bit prettier answer output than the standard terminal one
	        styled_completion_output_basic = @htl("""
	        <div style="
	            background-color: #f0f8ff;
	            border: 1px solid #4a90e2;
	            border-radius: 8px;
	            padding: 20px;
	            margin: 10px 0;
	            font-family: Arial, sans-serif;
	        ">
	            <h3 style="color: #2c5282; margin-top: 0;"> 🤖 Answer :</h3>
	            <div style="
	                background-color: white;
	                padding: 15px;
	                border-radius: 5px;
	                border-left: 4px solid #4a90e2;
	                line-height: 1.6;
	            ">
	                $(Markdown.parse(completion_result_basic))
	            
	        """)
	    else
	        # Fallback if ask is not defined or empty
	        styled_completion_output_basic = @htl("""
	        <div style="
	            background-color: #fff3cd;
	            border: 1px solid #ffeaa7;
	            border-radius: 8px;
	            padding: 20px;
	            margin: 10px 0;
	            font-family: Arial, sans-serif;
	        ">
	            <h3 style="color: #856404; margin-top: 0;">⚠️ no question found </h3>
	            <p style="margin: 0; color: #856404;">
	                please define the variable <code>ask</code> with your question 
	                <br><br>
	                Example: <code>ask = "How do I plot a function in Julia?"</code>
	            </p>
	        </div>
	        """)
	    end
	end
end

# ╔═╡ 7038c77f-91b5-4808-85be-b052e746d8aa
md"
## Here is a suggestion for a kind of copilot alternative
"

# ╔═╡ 94d3c463-a1d3-4766-bed1-0d7ae787be6d
md"""

!!! note
	Write some key words in **live_code** to get code suggestions. Unfortunately, there is still no autocomplete directly when writing the code. You have to start something and then send it to the LLM.

"""

# ╔═╡ 9b5ce7ae-ff1d-496a-af51-c4853c3ceeaf
live_code = """
	function rk4()

	"""


# ╔═╡ 5b225c4e-09e0-47e4-b46f-978287cf2a54
begin
	
	# based on the JavaScript code found in Playgroun
	
	# GitHub models API-function
	function github_models_chat(token, model_name, messages)
	    headers = [
	        "Authorization" => "Bearer $token",
	        "Content-Type" => "application/json"
	    ]
	    
	    body = JSON.json(Dict(
	        "model" => model_name,
	        "messages" => messages,
	        "temperature" => 1,
	        "max_tokens" => 4096,
	        "top_p" => 1
	    ))
	    
	    response = HTTP.post(
			# as in the JavaScript code: /chat/completions
	        "$base_url/chat/completions",
	        headers,
	        body
	    )
	    
	    return JSON.parse(String(response.body))
	end
	
	begin
	    function smart_complete(code_input)
	        if isempty(strip(code_input)) || length(strip(code_input)) < 5
	            return "Write at least 5 characters for completion..."
	        end

			#recognizes different code-patterns
	        patterns = [
	            (r"function\s+(\w+)\s*\(", "Funktionsdefinition"),
	            (r"for\s+\w+\s+in", "For-Schleife"),
	            (r"if\s+", "If-Statement"),
	            (r"while\s+", "While-Schleife"),
	            (r"using\s+(\w+)", "Package Import"),
	            (r"plot\s*\(", "Plot-Erstellung"),
	            (r"DataFrame\s*\(", "DataFrame-Erstellung"),
	            (r"=\s*\[", "Array-Definition")
	        ]
	        
	        detected_pattern = "Gerneral"
	        for (pattern, name) in patterns
	            if occursin(pattern, code_input)
	                detected_pattern = name
	                break
	            end
	        end
	        
	        completion_prompt = """
	        You are a Julia copilot. Complete the following code
 			for Pluto.jl:
	        
	        Detected pattern: $detected_pattern
	        so far my notebook has the following content: $clean_code 
	        
	        Code:
	        ```julia
	        $code_input
	        ```
	        
	        Rules:
			- Complete meaningfully and precisely
	        - Add English comments
	        - Pay attention to Julia best practices
	        - If already complete, optimize or expand
	        - Format the code nicely
	        """
	        
	        try
	            messages = [
	                Dict("role" => "system", "content" => "You are a helpful Julia programming assistant."),
	                Dict("role" => "user", "content" => completion_prompt)
	            ]
	            response = github_models_chat(github_token, model, messages)
	            return response["choices"][1]["message"]["content"]
	        catch e
	            return "Error: $e"
	        end
	    end
	    
	    completion_result = smart_complete(live_code)
		
	    
	    # Same output style as above: just a prettier output style than terminal
	    styled_completion_output = @htl("""
	    <div style="
	        background-color: #f0f8ff;
	        border: 1px solid #4a90e2;
	        border-radius: 8px;
	        padding: 20px;
	        margin: 10px 0;
	        font-family: Arial, sans-serif;
	    ">
	        <h3 style="color: #2c5282; margin-top: 0;">🤖 Code completion:</h3>
	        <div style="
	            background-color: white;
	            padding: 15px;
	            border-radius: 5px;
	            border-left: 4px solid #4a90e2;
	            line-height: 1.6;
	        ">
	            $(Markdown.parse(completion_result))
	        </div>
	    </div>
	    """)
	end
	
	
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
MacroTools = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
OpenAI = "e9f21f70-7185-4079-aca2-91159181367c"
Pluto = "c3e4b0f8-55cb-11ea-2926-15256bba5781"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
HTTP = "~1.10.16"
HypertextLiteral = "~0.9.5"
JSON = "~0.21.4"
LaTeXStrings = "~1.4.0"
MacroTools = "~0.5.16"
OpenAI = "~0.10.1"
Pluto = "~0.20.9"
PlutoUI = "~0.7.62"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.3"
manifest_format = "2.0"
project_hash = "c9d748f3d06e0e686536d7ea48ac4f47044a422b"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "d9d26935a0bcffc87d2613ce14c527c99fc543fd"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.0"

[[deps.Configurations]]
deps = ["ExproniconLite", "OrderedCollections", "TOML"]
git-tree-sha1 = "4358750bb58a3caefd5f37a4a0c5bfdbbf075252"
uuid = "5218b696-f38b-4ac9-8b61-a12ec717816d"
version = "0.17.6"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.ExpressionExplorer]]
git-tree-sha1 = "4a8c0a9eebf807ac42f0f6de758e60a20be25ffb"
uuid = "21656369-7473-754a-2065-74616d696c43"
version = "1.1.3"

[[deps.ExproniconLite]]
git-tree-sha1 = "c13f0b150373771b0fdc1713c97860f8df12e6c2"
uuid = "55351af7-c7e9-48d6-89ff-24e801d99491"
version = "0.10.14"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.GracefulPkg]]
deps = ["Compat", "Pkg", "TOML"]
git-tree-sha1 = "08e7c5a21fc7983388b532442408f04157190475"
uuid = "828d9ff0-206c-6161-646e-6576656f7244"
version = "2.2.0"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "f93655dc73d7a0b4a368e3c0bce296ae035ad76e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.16"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "411eccfe8aba0814ffa0fdf4860913ed09c34975"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.3"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.LRUCache]]
git-tree-sha1 = "5519b95a490ff5fe629c4a7aa3b3dfc9160498b3"
uuid = "8ac3fa9e-de4c-5943-b1dc-09c6b5f20637"
version = "1.6.2"
weakdeps = ["Serialization"]

    [deps.LRUCache.extensions]
    SerializationExt = ["Serialization"]

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LazilyInitializedFields]]
git-tree-sha1 = "0f2da712350b020bc3957f269c9caad516383ee0"
uuid = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Malt]]
deps = ["Distributed", "Logging", "RelocatableFolders", "Serialization", "Sockets"]
git-tree-sha1 = "02a728ada9d6caae583a0f87c1dd3844f99ec3fd"
uuid = "36869731-bdee-424d-aa32-cab38c994e3b"
version = "1.1.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.MsgPack]]
deps = ["Serialization"]
git-tree-sha1 = "f5db02ae992c260e4826fe78c942954b48e1d9c2"
uuid = "99f44e22-a591-53d1-9472-aa23ef4bd671"
version = "1.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenAI]]
deps = ["Dates", "HTTP", "JSON3"]
git-tree-sha1 = "d69de972e2c9140a42afc83a9e3331826d73e27e"
uuid = "e9f21f70-7185-4079-aca2-91159181367c"
version = "0.10.1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "f1a7e086c677df53e064e0fdd2c9d0b0833e3f6e"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.5.0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "9216a80ff3682833ac4b733caa8c00390620ba5d"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.0+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.Pluto]]
deps = ["Base64", "Configurations", "Dates", "Downloads", "ExpressionExplorer", "FileWatching", "GracefulPkg", "HTTP", "HypertextLiteral", "InteractiveUtils", "LRUCache", "Logging", "LoggingExtras", "MIMEs", "Malt", "Markdown", "MsgPack", "Pkg", "PlutoDependencyExplorer", "PrecompileSignatures", "PrecompileTools", "REPL", "RegistryInstances", "RelocatableFolders", "Scratch", "Sockets", "TOML", "Tables", "URIs", "UUIDs"]
git-tree-sha1 = "b8d8418bb773f073ad350effe8f2079205753e05"
uuid = "c3e4b0f8-55cb-11ea-2926-15256bba5781"
version = "0.20.9"

[[deps.PlutoDependencyExplorer]]
deps = ["ExpressionExplorer", "InteractiveUtils", "Markdown"]
git-tree-sha1 = "9071bfe6d1c3c51f62918513e8dfa0705fbdef7e"
uuid = "72656b73-756c-7461-726b-72656b6b696b"
version = "1.2.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "d3de2694b52a01ce61a036f18ea9c0f61c4a9230"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.62"

[[deps.PrecompileSignatures]]
git-tree-sha1 = "18ef344185f25ee9d51d80e179f8dad33dc48eb1"
uuid = "91cefc8d-f054-46dc-8f8c-26e11d7c5411"
version = "3.0.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegistryInstances]]
deps = ["LazilyInitializedFields", "Pkg", "TOML", "Tar"]
git-tree-sha1 = "ffd19052caf598b8653b99404058fce14828be51"
uuid = "2792f1a3-b283-48e8-9a74-f99dce5104f3"
version = "0.1.0"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.0"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "cbbebadbcc76c5ca1cc4b4f3b0614b3e603b5000"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─cb09ac75-9dad-4916-a0f4-0cac3fa03336
# ╟─05d4f57b-cb02-464c-9e18-f0b5b21ce7dc
# ╟─c53944f6-8dd0-4a79-a2b6-1c10b9a428db
# ╠═5d9a3300-902b-4a5f-ae9e-6b05f26ed572
# ╠═96a9b098-9e2f-4da7-aa3c-d8e760e699f2
# ╠═f4c593b3-93d2-4197-88e0-cd1d971e75ec
# ╟─0dc860c5-b320-4e3c-acc3-43abdf32d2d9
# ╟─1b61ad8b-706d-4f21-9460-f66f3e3cb821
# ╠═60859a39-519d-4a53-9160-932b793f9357
# ╠═04570601-84a5-4c5a-b7fc-0b0d1b3d8313
# ╟─57f92ae8-2e24-4390-9a86-206da6e3ed05
# ╟─7038c77f-91b5-4808-85be-b052e746d8aa
# ╟─94d3c463-a1d3-4766-bed1-0d7ae787be6d
# ╠═9b5ce7ae-ff1d-496a-af51-c4853c3ceeaf
# ╟─5b225c4e-09e0-47e4-b46f-978287cf2a54
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
