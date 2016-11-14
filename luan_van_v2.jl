#tạo ma trận location, chia nho map thanh 100 phần bằng nhau
using Clustering
d = 0.1; # Độ rộng của mỗi ô trên bản đồ
feature_hashing_lenght = 20; # Số lượng dữ liệu muốn đưa về khi sử dụng feature hashing

function CreateData()
	folderName = "Geolife Trajectories 1.3\\Data\\";
	minLatitudeAll = 0;
	maxLatitudeAll = 0;
	minLongitudeAll = 0;
	maxLongitudeAll = 0;
	
	for userFolder in readdir(folderName)
		preA = 0;
		preB = 0;
		
		f = open(string("userdata\\",userFolder,".txt"),"w");
		for fileInFolder in readdir(string(folderName,userFolder,"\\","Trajectory\\"))
			
			dismiss =1;
			
			open(string(folderName,userFolder,"\\","Trajectory\\",fileInFolder)) do filehandle

				for line in eachline(filehandle)
					if(dismiss>6)
						x = split(line,",");
						a = round(Int, parse(Float64,x[1])/d);
						b = round(Int, parse(Float64,x[2])/d);
						if(a != preA || b != preB)
						
							write(f,string(a,",",b," "));
							
							#update minLatitudeAll,minLongitudeAll,maxLatitudeAll,maxLongitudeAll;
							
							if minLatitudeAll == 0 || minLatitudeAll > a
								minLatitudeAll = a;
							end
							if maxLatitudeAll == 0 || maxLatitudeAll < a
								maxLatitudeAll = a;
							end
							if minLongitudeAll == 0 || minLongitudeAll > b
								minLongitudeAll = b;
							end
							if maxLongitudeAll == 0 || maxLongitudeAll < b
								maxLongitudeAll = b;
							end

							preA = a;
							preB = b;
						end
					end
					dismiss=dismiss+1;
				end
			 
			end
		end

		close(f);
		println(userFolder);
	end
	
	f = open("maxmin.txt","w");
	write(f,string(minLatitudeAll," ", maxLatitudeAll, " ", minLongitudeAll, " ", maxLongitudeAll));
	close(f);
	println("Data created");
end

function hashing_vectorizer(features,N)
	x = zeros(N);
	for f in features
		h = hash(f);
		x[h % N] += 1; 
	end
	return x;
end

function chay_kmean(X)
	# make a random dataset with 1000 points
	# each point is a 5-dimensional vector
	#X = rand(5, 21)

	# performs K-means over X, trying to group them into 20 clusters
	# set maximum number of iterations to 200
	# set display to :iter, so it shows progressive info at each iteration
	R = kmeans(X, 20; maxiter=200, display=:iter)

	# the number of resultant clusters should be 20
	@assert nclusters(R) == 20

	# obtain the resultant assignments
	# a[i] indicates which cluster the i-th sample is assigned to
	a = assignments(R)

	# obtain the number of samples in each cluster
	# c[k] is the number of samples assigned to the k-th cluster
	c = counts(R)

	# get the centers (i.e. mean vectors)
	# M is a matrix of size (5, 20)
	# M[:,k] is the mean vector of the k-th cluster
	M = R.centers

	println("Xử lý xong kmeans");
	writedlm("KetQuaKMean_a.txt",a);
	writedlm("KetQuaKMean_c.txt",c);
	writedlm("KetQuaKMean.txt",M);
end

function run()
	f = open("maxmin.txt","r");
	maxmin = readall(f);
	maxmin = split(maxmin," ");
	close(f);
	x = parse(Int,maxmin[2]) - parse(Int,maxmin[1]);
	y = parse(Int,maxmin[4]) - parse(Int,maxmin[3]);
	minLatitudeAll = parse(Int,maxmin[1]);
	maxLatitudeAll = parse(Int,maxmin[2]);
	minLongitudeAll = parse(Int,maxmin[3]);
	maxLongitudeAll = parse(Int,maxmin[4]);
	
	
	#Tao list tất cả các điểm của tất cả các user đã đi qua
	D = Dict();
	value = 1;
	folderName = "userdata\\";
	for fileName in readdir(folderName)
		#println(string(folderName,fileName));
		open(string(folderName,fileName)) do filehandle
			for line in eachline(filehandle)
				for p in split(line," ")
					p1 = split(p,",");
					if length(p1) == 2
						a = parse(Int,p1[1]) - minLatitudeAll;
						b = parse(Int,p1[2]) - minLongitudeAll;
						if haskey(D,string(a,",",b)) == false
							D[string(a,",",b)] = value;
							value = value + 1;
						end
					end
				end	
			end
			 
		end
	end
	print("Tao xong ma trận D(nx1) chứa tất cả các điểm có user đi qua ");
	println(length(D));
	
	#----------------------------------------------BUOC 2 -----------------------------------------------
	D2 = zeros(feature_hashing_lenght,182);
	D_temp = zeros(length(D),1);
	println(string("Map các điểm mà user đi qua lên ma trận D(nx1) sau đó sử dụng feature hashing để tạo ma tran D2 kich thuoc: ",size(D2)));
	
	currentUser = 1;
	for fileName in readdir(folderName)
		open(string(folderName,fileName)) do filehandle
			for line in eachline(filehandle)
				for p in split(line," ")
					p1 = split(p,",");
					if length(p1) == 2
						a = parse(Int,p1[1]) - minLatitudeAll;
						b = parse(Int,p1[2]) - minLongitudeAll;
						key = string(a,",",b);
						index = getindex(D,key);
						#D2[index,currentUser] = 1;
						D_temp[index,1] = 1;
					end
				end	
			end
		end
		hashing_result = hashing_vectorizer(D_temp,feature_hashing_lenght);
		for result in 1:feature_hashing_lenght
			D2[result,currentUser] = hashing_result[result];
		end
		currentUser = currentUser + 1;
	end
	writedlm("D2.txt",D2);
	println("Map xong các điểm mà user đi qua lên ma trận D2, mỗi user là một cột");
	#-------------------------------------------------------BUOC 3------------------------------------------------
	println("Bắt đầu bước 3");
	D3 = zeros(feature_hashing_lenght,feature_hashing_lenght);
	D4 = zeros(feature_hashing_lenght*feature_hashing_lenght,182);
	println(string("Tạo ma trận di chuyển của mỗi user, mỗi ma trận có kích thước size = ",size(D3)));
	println(string("Convert ma trận di chuyển của mỗi user thành vector nx1, xem mỗi user là 1 cột, ghép lại thành 1 ma trận với kích thước = ", size(D4)));
	

			
	for u in 1:182
		D3 = zeros(feature_hashing_lenght,feature_hashing_lenght);
		prePosition = -1;
		for i in 1:feature_hashing_lenght
			if D2[i,u] > 0
				if prePosition == -1
					prePosition = i;
				else
					D3[prePosition,i] = 1;
					prePosition = i;
				end

			end
		end
		
		DTemp = reshape(D3,feature_hashing_lenght*feature_hashing_lenght,1);
	
		for i in 1:length(DTemp)
			D4[i,u] = DTemp[i,1];
		end
	end
	
			
	println(string("Tao xong du lieu dua vao k-mean ",size(D4)));
	writedlm("KMeanData.txt",D4);
	println("Ghi xong dữ liệu vô KMeanData.txt");
	
	chay_kmean(D4);
end


