//
//  RandomizerViewModel.swift
//  modeladoapp
//
//  Created by Luis Roberto Martinez on 25/11/24.
//

/*
 TO DO:
 1) optimize api related functions
 2) delete/move gallery function placeholders
 */

import SwiftUI
import Combine

class RandomizerViewModel: ObservableObject {
    
    @Published var cat: CatModel?
    @AppStorage("totalCount") var totalCount: Int = 0
    @Published var sessionCount: Int = 0
    
    @Published var image: UIImage?
    
    var canceallables = Set<AnyCancellable>()
    
    
    let countersManager = CatCountManager.shared
    let imagesService = ImagesDataService.shared
    
    init() {
        addSessionCountObserver()
        getCat()
    }
    
    
    // MARK: methods
    
    // Api call to fech a random cat
    func getCat() {
        guard let url = URL(string: catApiUrlStringSingle) else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .tryMap(handleOutput)
            .decode(type: [CatModel].self, decoder: JSONDecoder())
            .sink { completion in
                print(completion)
            } receiveValue: { [weak self] data in
                let newCat = data[0]
                self?.cat = newCat
                self?.countersManager.increase()
                self?.loadImage()
            }
            .store(in: &canceallables)
    }
    
    // handles api call output
    func handleOutput(output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard
            let response = output.response as? HTTPURLResponse,
            (200..<300).contains(response.statusCode) else {
            print("handleOutput failed")
            throw URLError(.badServerResponse)
        }
        print("hehe")
        return output.data
    }
    
    
    func getImageURL() -> URL? {
        cat?.getURL()
    }
    
    // pulls image from the URL
    func loadImage() {
        guard let url = getImageURL() else {
            print("cant get cat url")
            return
        }
        
        // the whole task was not stored properly and it was being deallocated
        // so it seems like storing in cancellables really is that important
        //let task = // this ref. was being dumped
        URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .tryMap(handleOutput)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Image fetch completed successfully.")
                case .failure(let error):
                    print("Image fetch failed with error: \(error)")
                }
            } receiveValue: { [weak self] data in
                let newImage = UIImage(data: data)
                self?.image = newImage
            }
            .store(in: &canceallables)
        print("loadImage() finish")
    }
    
    // Observes any changes on the manager´s count variable
    func addSessionCountObserver() {
        countersManager.$sessionCount.assign(to: &$sessionCount)
    }
    
    // saves/unsaves the image from the local storage
    func saveButtonPressed() {
        guard let id = cat?.id, let image else { return }
        if imagesService.isImageSaved(key: id) {
            imagesService.delete(key: id)
        } else {
            imagesService.add(key: id, value: image)
        }
    }
    
    // MARK: GALLERY FUNCTIONS
    
    func moveImage() {
        
    }
    
    func getImages() -> [Photo] {
        imagesService.getAll() ?? []
    }
    
}

