
################################
# Phương pháp theo ngẫu nhiên (Random Walk)
# Xét một điểm A bất kỳ trên quỹ đạo di chuyển của user, khả năng tiếp theo user sẽ di chuyển đến 1 trong 8 điểm xung quanh
# Dự đoán điểm đến tiếp theo dựa trên tỷ lệ random từ 1 đến 8.
################################
test_user_count = 182;
minLatitudeAll = 10;
maxLatitudeAll = 4002;
minLongitudeAll = -1800;
maxLongitudeAll = 1800;
maxLenghtTrajectory = 10104;

#Tạo vector quỹ đạo di chuyển của user u từ file dữ liệu đã chuyển đổi
# u: index của user
function create_user_trajectory(u)
 m = maxLatitudeAll - minLatitudeAll;
 v = Int64[];

 open(string("userdata/",get_file_name(u))) do filehandle
     for line in eachline(filehandle)
       for p in split(line," ")
         p1 = split(p,",");
         if length(p1) == 2
           a = parse(Int,p1[1]) - minLatitudeAll;
           b = parse(Int,p1[2]) - minLongitudeAll;
           index = ((a-1)*m) + b;
           push!(v,index);
         end
       end
     end
 end
 return v;
end


# Lấy tên file của user u
function get_file_name(u)
	if u < 10
		return string("00",u,".txt");
	elseif u < 100
		return string("0",u,".txt");
	else
		return string(u,".txt");
	end
end

# Hàm lấy các thông số min max latitude và longitude từ dữ liệu đã chuyển đổi.
# Kết quả được set và các biến toàn cục minLatitudeAll, maxLatitudeAll, minLongitudeAll, maxLongitudeAll.
function set_max_min_config_from_data()
	f = open("maxmin.txt","r");
	maxmin = readall(f);
	maxmin = split(maxmin," ");
	close(f);

	minLatitudeAll = parse(Int,maxmin[1]);
	maxLatitudeAll = parse(Int,maxmin[2]);
	minLongitudeAll = parse(Int,maxmin[3]);
	maxLongitudeAll = parse(Int,maxmin[4]);
	maxLenghtTrajectory = parse(Int,maxmin[5]);
end

# Lấy index của điểm cần dự đoán trên ma trận quỹ đạo
# current_index: điểm hiện tại của user
# predict_index: 1,2,3,4,5,6,7,8. điểm dự đoán kế tiếp
function GetIndexOfPredictPosition(current_index, predict_index)
  m = maxLatitudeAll - minLatitudeAll;
  b = current_index % m;
  a = convert(Int,(current_index - b) / m);
  if(predict_index == 1)
    return ((a-1)*m) + (b-1);
  elseif(predict_index == 2)
    return ((a-1)*m) + b;
  elseif(predict_index == 3)
    return ((a-1)*m) + (b+1);ßß
  elseif(predict_index == 4)
    return ((a)*m) + (b+1);
  elseif(predict_index == 5)
    return ((a+1)*m) + (b+1);
  elseif(predict_index == 6)
    return ((a+1)*m) + b;
  elseif(predict_index == 7)
    return ((a+1)*m) + (b-1);
  else
    return ((a)*m) + (b-1);
  end
end

# Chạy phân tích dữ liệu training
# Lấy vector các điểm di chuyển của user
# Chuyển thành ma trận quỹ đạo
#
function run()
	set_max_min_config_from_data();
  true_predict_count = 0;
  false_predict_count = 0;
  for i = 1:test_user_count
      v = create_user_trajectory(i-1);println(string("Test user ",i));
      #println(length(v));
      if length(v) >= 2
          current_index = v[length(v)-1];println(string("diem dang test ",current_index));
          next_index = v[length(v)];println(string("diem den ke tiep ",next_index));
          random_value = rand([1,2,3,4,5,6,7,8]);
          predict_next_index = GetIndexOfPredictPosition(current_index,random_value);

          # so sanh diem du doan voi diem den ke tiep tren thuc te
          if(predict_next_index == next_index)
            true_predict_count  = true_predict_count + 1;println("Du doan dung");
          else
            false_predict_count  = false_predict_count + 1;println("Du doan sai");
          end


      end

  end

  println(string("Tong so lan du doan dung: ", true_predict_count));
  println(string("Tong so lan du doan sai: ", false_predict_count));
  println(string("Ty le du doan dung: ", true_predict_count/(true_predict_count+false_predict_count)*100));

end
