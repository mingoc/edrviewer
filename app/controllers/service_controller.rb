# coding: utf-8
require 'pstore'
require 'time'
class ServiceController < ApplicationController
  def index()

    store=PStore.new 'db/edr.store'
    @services=store.transaction(true) { store.roots - [:files] }    
    @service= params[:name]? params[:name]:@services[0]

    all_edrs_by_time=store.transaction(true){store[@service.to_sym]}
  
    @to= if params["to"]           
           Time.parse(params["to"]+" 23:59:59")
         elsif session[:service_to]           
           Time.parse(session[:service_to]+" 23:59:59")
         else
           all_edrs_by_time.keys.sort.last
         end
    @from= if params["from"]
             Time.parse(params["from"]+" 00:00:00")
           elsif session[:service_from]
             Time.parse(session[:service_from]+" 00:00:00")
           else
             @to-3*24*3600
           end

    session[:service_from]=@from
    session[:service_to]=@to

    edrs_by_time=all_edrs_by_time.select{|key, values| key>=@from && key <=@to }
    
    codes=edrs_by_time.values.map{|stat| stat.keys}.flatten.uniq
    datas1 = codes.map do |code|
              edrs_by_time.keys.inject({}) do |hash, time|
                hash[time]=edrs_by_time[time][code]?edrs_by_time[time][code]:0
                hash                                                    
              end      
    end
    @edrs1=Hash[codes.zip(datas1)]  #request count

    datas2 = codes.map do |code|
      edrs_by_time.keys.inject({}) do |hash, time|
        hash[time]= unless edrs_by_time[time][code]
                      0
                    else
                      edrs_by_time[time][code]/edrs_by_time[time].values.reduce(:+).to_f * 100
                    end          
        hash                                                    
      end      
    end
    @edrs2=Hash[codes.zip(datas2)]  #request percentage    
  end 
end
