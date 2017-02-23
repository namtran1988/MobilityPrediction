
################################
# Phương pháp theo số đông (Follow the Ground)
# Xét một điểm A bất kỳ trên quỹ đạo di chuyển của user, khả năng tiếp theo user sẽ di chuyển đến 1 trong 8 điểm xung quanh
# Dự đoán điểm đến tiếp theo dựa trên tỷ lệ di chuyển cao nhất của những user khác từng đến A.
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
          predict_index_1 = GetIndexOfPredictPosition(current_index,1);print(string(predict_index_1," "));
          predict_index_2 = GetIndexOfPredictPosition(current_index,2);print(string(predict_index_2," "));
          predict_index_3 = GetIndexOfPredictPosition(current_index,3);print(string(predict_index_3," "));
          predict_index_4 = GetIndexOfPredictPosition(current_index,4);print(string(predict_index_4," "));
          predict_index_5 = GetIndexOfPredictPosition(current_index,5);print(string(predict_index_5," "));
          predict_index_6 = GetIndexOfPredictPosition(current_index,6);print(string(predict_index_6," "));
          predict_index_7 = GetIndexOfPredictPosition(current_index,7);print(string(predict_index_7," "));
          predict_index_8 = GetIndexOfPredictPosition(current_index,8);print(string(predict_index_8," "));
          count_1 = 0; count_2 = 0; count_3 = 0; count_4 = 0; count_5 = 0; count_6 = 0; count_7 = 0; count_8 = 0;

          for j in 1:test_user_count
              if(j!=i)
                  v1 = create_user_trajectory(j-1)
                  flag = 0;
                  for l in v1
                      if l==current_index;
                          flag = 1;
                      end

                      if (l != current_index && flag == 1)
                          flag = 0;
                          if l == predict_index_1
                            count_1 = count_1 + 1;
                          elseif l == predict_index_2
                            count_2 = count_2 + 1;
                          elseif l == predict_index_3
                            count_3 = count_3 + 1;
                          elseif l == predict_index_4
                            count_4 = count_4 + 1;
                          elseif l == predict_index_5
                            count_5 = count_5 + 1;
                          elseif l == predict_index_6
                            count_6 == count_6 + 1;
                          elseif l == predict_index_7
                            count_7 = count_7 + 1;
                          elseif l == predict_index_8
                            count_8 = count_8 + 1;
                          end
                      end

                  end
              end
          end
          #kiem tra diem di chuyen ke tiep duoc nhieu nguoi lua chon nhat
          max_count = count_1;
          predict_next_index = predict_index_1;
          if(count_2>max_count)
            max_count = count_2;
            predict_next_index = predict_index_2;
          end
          if(count_3 > max_count)
            max_count = count_3;
            predict_next_index = predict_index_3;
          end
          if(count_4 > max_count)
            max_count = count_4;
            predict_next_index = predict_index_4;
          end
          if(count_5 > max_count)
            max_count = count_5;
            predict_next_index = predict_index_5;
          end
          if(count_6 > max_count)
            max_count = count_6;
            predict_next_index = predict_index_6;
          end
          if(count_7 > max_count)
            max_count = count_7;
            predict_next_index = predict_index_7;
          end
          if(count_8 > max_count)
            max_count = count_8;
            predict_next_index = predict_index_8;
          end
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
